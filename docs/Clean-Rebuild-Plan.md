# FanControl clean rebuild plan

## Task for the next agent

Recreate the working sandboxed FanControl and privileged-component installation flow cleanly on a separate branch
Use this document as the implementation plan and the existing working files as a reference, not as a patch to copy wholesale
Deliver a signed, notarized, offline test app that works on a regular Mac without Xcode
Preserve the current app’s unrelated functionality and user edits

The user confirmed the final implementation fully works
Do not repeat the intermediate installer designs or require manual component downloads, drag-and-drop installation, terminal commands or a separate setup wizard

## 1 — Preserve the reference and establish the baseline

- Read AGENTS.md and the asc-notarization skill before implementation and distribution work
- The working reference is branch `sandbox-external-helper`
- Its recorded HEAD is `c8c7fb68633577b1bb41611299b1f323290b829a`, but the implementation is in uncommitted and untracked files — that commit alone does not contain it
- Save a recoverable reference of tracked changes and untracked source files before switching branches or cleaning anything
- Inspect the intended base commit and distinguish this feature’s changes from unrelated changes, particularly fan presets and fan views
- Create a separate implementation branch in the main project as requested by the repository rules
- Do not reset, discard changes, delete old artifacts, alter existing service approvals or remove installed helpers as incidental cleanup
- Do not copy the entire current FanVM or Xcode project file without reviewing the relevant changes

Exit condition: the working reference is recoverable and the new branch has an explicit, understood baseline

## 2 — Fix the scope and architecture before coding

### Required user flow

1. Open FanControl
2. If the helper is unavailable, show an “Install FanControl components?” alert with Install and Not now
3. Install launches the bundled, signed component installer automatically
4. The installer copies its complete bundle into the user’s Application Support directory
5. It registers the privileged daemon and opens macOS Login Items & Extensions when approval is needed
6. After the user approves, registration completes automatically and FanControl reconnects
7. The installer exits after a successful XPC handshake and FanControl shows working controls and live readings

Normal macOS authorization and Gatekeeper prompts remain possible
Do not try to bypass them or remove quarantine attributes

### Three distinct responsibilities

| Piece | Responsibility | Privileges |
| --- | --- | --- |
| FanControl | SwiftUI UI, remote XPC client, installation alert and connection state | App Sandbox |
| FanControl Component | Install/update orchestration, SMAppService registration, approval tracking | Normal unsandboxed user process |
| FanControlHelper | Validated fan commands, hardware reads and writes, safety restoration | Root launch daemon |

The sandboxed app must not directly access SMC hardware or register the privileged daemon
Keep hardware implementation and CoreSMC out of the main app’s linked dependencies
Use the existing CoreSMC dependency in the helper rather than introducing another framework

### Stable identifiers

| Purpose | Value |
| --- | --- |
| Signing team | `8FQUA2F388` |
| Main app | `dev.topscrech.FanControl` |
| Component app | `dev.topscrech.FanControl.component` |
| Helper executable signing identifier | `dev.topscrech.FanControl.helper` |
| Component Mach service and launchd label | `dev.topscrech.FanControl.component.helper` |
| launchd plist filename | `dev.topscrech.FanControl.helper.plist` |
| Temperature executable signing identifier | `dev.topscrech.FanControl.ismc` |
| Existing authorized CLI identifier | `dev.topscrech.FanControl.fan` |

The plist filename and its Label intentionally differ
The component service is distinct from the old direct-download app’s daemon
The working component version is 1.7 and XPC protocol version is 1
Choose a newer component version when testing replacement of an already installed 1.7 build
Do not advance protocol version merely because installer implementation changes

### Distribution boundary

The requested offline test package embeds both the component ZIP and its already-expanded installer app
The expanded installer belongs at `FanControl.app/Contents/Helpers/FanControl Component.app`
Expansion happens during release packaging, before the outer app’s final signature

This is a Developer ID test-distribution design
App Store acceptance and a production external-component delivery mechanism have not been established by this work
Keep test embedding out of the normal App Store artifact and do not publish a release or submit to App Review as part of this task

Exit condition: targets, identifiers, installation flow and test-distribution boundary are explicit

## 3 — Implement transport and helper first

Use Shared/Component, Shared/XPC, Shared/SMC/RemoteSMCService.swift and FanControlHelper as reference locations

- Define the XPC contract for component information, fans, temperatures, manual RPM, automatic mode, keep-alive and preparation for updates
- Use stable explicit Objective-C names for cross-process protocol and securely coded snapshot types
- Keep transport models independent of CoreSMC for the sandboxed app
- Require Apple-anchored signatures with the expected team and identifiers on both XPC peers
- Keep the client allowlist narrow and validate it for every new connection
- Require protocol compatibility before enabling fan controls
- Give every request a deadline and cancellation handling with exactly-once continuation completion
- Validate fan IDs, finite RPM values and hardware limits before any write
- Give manual control a single connection owner and a 10-second heartbeat lease
- Restore automatic control on owner disconnect, lease expiry, preparation for update and orderly termination
- Track partial writes and failed restorations so they can be retried
- Reject new manual writes once update preparation begins
- Keep signal handling and service work independent of UI lifetime

### Temperature reader

Run only the component’s bundled, signature-validated iSMC with fixed arguments
Use restricted environment variables, bounded output, a deadline, short-lived caching and coalesced reads
Resolve the actual running helper path with `_NSGetExecutablePath`, then locate its sibling iSMC
Never derive this path from `CommandLine.arguments[0]` — launchd supplied a relative argv[0], causing a false signature failure

Exit condition: helper and transport build, and hardware-free tests pass

## 4 — Implement installation as an explicit lifecycle

Reference: FanControlComponent and FanControl/Features/Component
Prefer small services with clear ownership over a single large installer model

### Main app

- Own shared installation state in an observable model used through the environment
- Prompt once per launch after a failed helper connection, with a visible retry action
- Verify the expanded component bundle’s exact signature before launching it
- Use NSWorkspace/LaunchServices for this first launch from the sandbox
- Request a new component instance so an old running copy does not substitute for the selected installer
- Wait for the helper handshake and reconnect automatically
- Expose actionable failures, including error domain/code and the failed stage
- Keep “installing”, “waiting for approval”, “connecting”, “ready” and “failed” distinguishable

### Component installer

- Start orchestration from application launch/delegate code, not a SwiftUI view `.task`
- Run maintenance modes without requiring a window to appear
- Use `~/Library/Application Support/dev.topscrech.FanControl.component/FanControl Component.app` as the installed location
- Compare canonical paths rather than raw URL equality — a directory URL’s trailing slash previously caused self-reinstallation
- Verify an existing installed bundle before trusting or executing it
- Preserve registration when the same component version is already installed
- For a real update: establish the current service state, restore automatic control, block new writes, unregister, then replace the complete signed bundle
- Fail safely if restoration cannot be confirmed for a running helper
- Stage the replacement and retain a recoverable previous bundle until the new one is validated
- Re-verify the copied bundle before starting it
- Start the installed executable with Process from the already-launched unsandboxed installer, then exit the source installer
- Do not use LaunchServices for that second launch — this produced App Translocation mount conflicts and OSStatus −47
- Do not launch an old GUI process and wait indefinitely for its view to execute an unregister command

### Registration and approval

- A register call can return EPERM while approval is pending
- Distinguish that case from other registration failures using both NSError details and service status
- Open Login Items & Extensions for the pending approval state
- Background permission being on does not by itself prove the daemon is registered or running
- Retry failed registration after approval without repeatedly unregistering
- Bound retries and report the actual failure state on timeout
- Finish only after a successful helper handshake

### Clean implementation requirements beyond the prototype

The reference proves the flow, but it is not a reason to retain every shortcut

- Serialize concurrent install/update attempts and avoid multiple installer processes racing over the bundle
- Keep state transitions testable without root access
- Ensure an unavailable version handshake cannot silently skip restoration for a known running helper
- Avoid interpreting every error whose numeric code happens to be 1 as authorization failure
- Prevent automatic downgrades and define how version/build identity determines replacement
- Replace obsolete comments and remove unused download actions, old view-driven startup and dead maintenance paths
- Do not carry compatibility branches for every intermediate 1.0–1.6 experiment unless an actual supported migration needs them

Exit condition: installation, approval, same-version retry and replacement have deterministic, bounded paths

## 5 — Integrate the sandboxed app without unrelated rewrites

- Enable App Sandbox and the narrow Mach lookup exception for the component service
- Preserve needed network and CloudKit entitlements
- Route fan reads, temperatures and fan writes through the helper
- Keep the app’s fan controls and existing unrelated feature behavior intact
- Comment code responsible for license purchasing, activation, verification, credential storage and license-based restrictions, as requested by the user
- Remove license gates from the active fan-control path without deleting their preserved source
- Disable incompatible startup behavior: direct CLI installation, self-moving, old hardware launch reporting and direct-distribution updater actions
- Preserve opt-in launch-at-login behavior
- Use a persisted container-scoped installation identifier where the previous remote identity path depended on hardware access
- Review each ancillary change rather than copying every modification from the experimental branch
- Follow AGENTS.md: no simulator, no new third-party dependencies, separate types/views, environment models and modern concurrency

Exit condition: the app builds sandboxed with only the intended feature changes

## 6 — Package once the implementation is validated

Reference scripts:

- `scripts/release_component.sh`
- `scripts/release_embedded_component_test.sh`

Use the user’s original `release_fancontrol.sh` as the signing/notarization baseline and leave that original unchanged
Its supplied location is under the user’s iCloud Drive “Release scripts” directory

Existing signing setup:

- Developer ID Application: Sergei Saliukov (8FQUA2F388)
- Existing notary keychain profile: AC_NOTARY
- No Developer ID Installer certificate was available or needed for this app-bundle flow

Sequence:

1. Build both architectures of the component and helper
2. Sign every nested executable, including each retained iSMC copy, then sign the component app
3. Notarize and staple the component app and recreate its ZIP with the stapled app inside
4. Build/archive the main app with the temporary embedded ZIP resource
5. Export through Xcode’s Developer ID distribution flow to obtain the correct distribution provisioning profile
6. Expand the component into Contents/Helpers during packaging
7. Sign the outer app again, preserving the exported entitlements, requirements and runtime flags
8. Verify nested signatures, notarize the final app ZIP, staple the app and recreate the final ZIP
9. Validate Gatekeeper acceptance and record a checksum
10. Remove only temporary resources created by this release run

Do not merely re-sign a development-provisioned main app
Verify Production CloudKit, `ProvisionsAllDevices = true`, App Sandbox enabled and no get-task-allow entitlement
Keep credentials and generated app bundles/archives outside source control
Keep one clearly named final output and a concise validation record rather than a series of “fixed” release folders

## 7 — Acceptance tests before delivery

### Automated, no hardware writes

Retain the existing engine, XPC completion and secure-coding coverage
The reference suite has 10 passing tests
Add meaningful lifecycle coverage for approval retry, repeated install, update restoration failure and concurrent install requests
Avoid tests that merely duplicate the implementation

### Actual distribution and runtime tests

| Scenario | Required evidence |
| --- | --- |
| Fresh regular Mac | Install alert appears and no Xcode/developer provisioning is needed |
| Quarantined download | First launch passes normal Gatekeeper checks and installer handoff succeeds |
| Approval pending | Installer explains approval and remains recoverable |
| Approval granted | Service registration completes and launchd reports the helper running |
| Connection | FanControl completes protocol handshake and displays live fan RPMs |
| Temperatures | CPU/GPU/battery data is displayed, with unavailable sensors handled normally |
| Same-version retry | Existing service remains running and is not unregistered |
| Update | Automatic fan control is restored before replacement and connection recovers |
| No restored window | Maintenance/startup work still runs and terminates when complete |
| Failure | Bad signatures, incompatible protocol and unavailable helper produce bounded errors |

Use a genuinely quarantined copy, not only the locally built app
Do not clear quarantine to make the test pass
A signed sandboxed launch probe was useful, but it did not replace testing the complete packaged app

Verify manual commands and restoration deliberately on suitable hardware after read-only checks pass
Avoid running competing fan controllers during those tests
Do not infer working fan control from notarization, an enabled background toggle or a running installer window

### Evidence from the working reference

- Component 1.7 registered and ran as a root daemon
- The main app showed both fan RPM readings and CPU/GPU/battery temperatures
- Reinstalling 1.7 kept the existing helper PID unchanged
- The final main app and component passed notarization and Gatekeeper assessment
- The user subsequently confirmed that it fully works

## 8 — Deliverables and stopping condition

Deliver a focused branch, coherent source layout, documented installation/update flow, reusable release scripts, final signed ZIP and a short validation report
Include any remaining App Store distribution questions separately from the verified Developer ID test flow
Do not claim App Store approval, clean-Mac validation or hardware behavior that was not actually checked
Do not publish, push or delete the working reference merely to finish this task

The implementation is complete when the final packaged app passes the acceptance flow, not when compilation or signing succeeds

## Known-good local reference artifact

The final test package from this session is:

`~/Downloads/FanControl-Background-Approval-Fix/FanControl-signed.zip`

It contains component 1.7
Earlier Downloads artifacts named Automatic-Install, Launch-Fixed or Error47-Fix are intermediate builds and must not be used as the implementation baseline
