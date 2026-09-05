# Sandboxed FanControl component

## Baseline

`sandbox-2` starts at `c8c7fb6` on `v2.0`
The reference implementation is preserved on `sandbox-external-helper` at `f0f8647`
At the start of this rebuild the checkout was clean and the prototype had already been committed, superseding the pasted plan's note about uncommitted source
A recoverable Git bundle containing all refs was also saved outside the repository
No reference branch, installed helper or existing service approval was removed as cleanup

The reviewed reference transport, fan engine and target structure underpin this branch
The installer lifecycle was rebuilt into separate bundle, registration, locking and presentation services
Existing presets, fan layouts, remote CloudKit features and language settings remain, with license code commented and its active restrictions disabled

## Process boundaries

| Process | Signing identifier | Responsibility |
| --- | --- | --- |
| Sandboxed app | `dev.topscrech.FanControl` | UI, XPC connection, installation alert |
| Unsandboxed component | `dev.topscrech.FanControl.component` | Verified bundle installation, service registration, approval |
| Root daemon | `dev.topscrech.FanControl.helper` | Validated hardware commands and temperature reads |

Team: `8FQUA2F388`
Component version: 1.11, build 0, protocol 1
Mach service and launchd Label: `dev.topscrech.FanControl.component.helper`
Plist filename: `dev.topscrech.FanControl.helper.plist`
The filename intentionally differs from the label, and the service is distinct from the old direct-distribution daemon
CoreSMC is linked by the helper and hardware test target, not by the sandboxed app or installer
The app retains network and CloudKit entitlements and one explicit global Mach lookup exception

## Installation and updates

1. A failed connection presents one installation alert per app launch, with a visible retry/check action
2. Install verifies the embedded component's Apple-anchored team and exact identifier before launching a fresh instance through NSWorkspace
3. The component starts from its application delegate, even without a restored window
4. An advisory file lock serializes installer processes under the component's Application Support directory
5. The full signed bundle is staged and verified, then installed at `~/Library/Application Support/dev.topscrech.FanControl.component/FanControl Component.app`
6. An equal or newer installed version/build is retained without unregistering
7. A real replacement requires confirmed automatic restoration for any enabled or responsive service, then unregisters before replacing files
8. A previous signed bundle is retained under a unique `previous-*.app` name, and a failed filesystem replacement rolls back
9. The already-launched unsandboxed process uses Process to start the verified installed executable, then exits and releases its lock
10. The installed process registers the daemon and opens Login Items & Extensions if approval is required
11. Registration retries without unregistering, including known SMAppService/POSIX permission errors before requiresApproval appears, with bounded attempts and error domain/code in failures
12. Success requires a compatible handshake from the expected component version; the main app reconnects automatically

The source and destination use canonical paths, avoiding self-reinstallation caused by trailing slashes
Downgrades are prevented by numeric version ordering, then numeric build ordering
A failed update restoration blocks subsequent manual writes and can be retried
A failure after successful replacement leaves the previous bundle recoverable; it does not silently execute old code or bypass approval

The installer has authoritative macOS approval state
The sandboxed app reports that it is waiting for the component and directs the user to any installer approval prompts; it does not infer registration from a background toggle

## Transport and safety

Both XPC peers enforce Apple-anchored signatures with the expected team and a narrow identifier allowlist before resume
Protocol and secure-coding class names are stable across Swift modules
Requests have five-second deadlines, cancellation and exactly-once continuation completion
Manual writes validate fan IDs, finite RPM values and supported limits
One connection owns manual control with a ten-second heartbeat lease
Disconnect, lease expiry, update preparation and termination restore automatic control
Partial writes are tracked before touching hardware, and failed restorations remain tracked for retry
The temperature reader resolves its running executable with `_NSGetExecutablePath`, validates its sibling iSMC, fixes arguments/environment, limits output and duration, and coalesces/caches reads

Apple references: [XPC signing requirements](https://developer.apple.com/documentation/foundation/nsxpcconnection/setcodesigningrequirement(_:)), [service registration](https://developer.apple.com/documentation/servicemanagement/smappservice/register()), [approval status](https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/requiresapproval)

## Build and package

Hardware-free tests:

```sh
xcodebuild -project FanControl.xcodeproj -scheme FanControl \
  -destination 'platform=macOS' -derivedDataPath /tmp/FanControlTests \
  test CODE_SIGNING_ALLOWED=NO
```

Create the signed, stapled universal component ZIP using `scripts/release_component.sh`, then pass that ZIP to `scripts/release_embedded_component_test.sh`
Output directories and signing/notary settings can be overridden with the environment variables documented in the scripts
The original external `release_fancontrol.sh` is unchanged

The test packaging script temporarily embeds the component ZIP as a resource, archives/exports the app through Xcode's Developer ID flow, expands the installer into Contents/Helpers, preserves exported signing metadata, and signs/notarizes/staples the complete app
`scripts/validate_distribution.sh` rejects missing sandboxing, development CloudKit, device-specific provisioning, get-task-allow, non-universal binaries and invalid signatures
The temporary source resource is removed on exit; signed artifacts remain outside source control

## Distribution boundary

This is an offline Developer ID test package
The expanded installer and ZIP are added only by the test release script
A normal app archive contains neither payload and needs a separately established component delivery mechanism
App Store acceptance, entitlement approval and production external-component delivery remain unverified
No release is published, pushed or submitted to App Review by these scripts

## Acceptance evidence

See `Sandbox-Validation.md` for checks actually performed and remaining external validation
A notarization ticket or passing unit tests alone does not prove a clean-Mac installation or real hardware behavior

Component 1.11 adds bounded recovery for interrupted restoration connections — see `XPC-Restoration-Recovery.md`
