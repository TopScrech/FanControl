# Sandboxed FanControl and its external component

The `FanControl` scheme builds the sandboxed Mac app
The `FanControl Component` scheme builds the external companion and embeds the root helper, launchd plist and temperature reader
The app uses a transport-only fan model and does not link CoreSMC
The helper, companion and test targets use Swift 6
The sandboxed app does not register the root service itself, install the CLI, move itself, start a direct-download updater or send the old launch hardware report
The Developer ID test release embeds a signed component archive and launches its installer after user consent
The embedded archive is injected only by the test release script and is not checked into source control
License purchase, activation, credential storage and preset restrictions are commented out
Launch at login is opt-in

## Installation and updates

Follow `Component Installation.txt` distributed in the DMG
The app presents an Install components alert, verifies the bundled component signature and launches it directly from Contents/Helpers
The companion automatically installs its complete bundle in the user Library/Application Support/dev.topscrech.FanControl.component folder before registration
The user approves its background service through macOS
The service uses `dev.topscrech.FanControl.component.helper`, distinct from the existing direct-download app's service
Stop the old direct-download app before using this version — two independent fan controllers must not run together

When launched, a replacement installer restores automatic control through XPC and unregisters the service before replacing the complete bundle
Installing the same version again preserves the existing registration
Service startup runs from the application delegate even if macOS restores no windows
After approval, failed registration is retried until launchd accepts it
A failed restoration prevents replacement
The installed copy registers itself, opens System Settings if approval is required, then waits for a successful helper handshake and exits
FanControl reconnects automatically
Never patch a signed nested executable in place
Legacy manually installed 1.0 copies must be stopped using their existing UI before removal

FanControl retries unavailable connections every 10 seconds and checks protocol compatibility before enabling controls
A protocol mismatch displays an update instruction instead of sending fan commands
`ComponentConfiguration.version` is the component release version, independent of the app version
`protocolVersion` describes the XPC contract — change it for incompatible changes and retain old protocol support when practical
New optional functionality should be capability-negotiated if introduced later
The current protocol implements the full fan/temperature contract and requires an exact version match

## Safety and trust boundaries

Both XPC peers require Apple-anchored signatures with the expected team and bundle identifiers
The helper accepts only FanControl, its companion and the CLI identifiers
A CLI must be rebuilt against the new protocol to connect to this component
Only one XPC connection owns manual fan control at a time
Fan IDs, finite RPM values and hardware limits are checked before writing
Automatic control is restored on owner disconnect, a 10-second expired heartbeat, preparation for updates and orderly SIGTERM/SIGINT shutdown
Restoration failures remain tracked for retry
SIGKILL, power loss, kernel/SMC failures and a hung kernel call cannot be recovered by a userspace watchdog

Temperature reads execute only the bundled, signature-validated iSMC binary, with fixed arguments, a restricted environment and a deadline
Output is cached briefly and concurrent requests share one sample
There is no API for arbitrary shell commands, executable paths or general SMC key writes

## Build, test and release

```
xcodebuild -project FanControl.xcodeproj -scheme FanControl -destination 'platform=macOS' test
scripts/release_component.sh
```

The release script is based on the supplied `release_fancontrol.sh`
It uses Developer ID Application signing and the existing AC_NOTARY keychain profile
It archives both CPU architectures, signs nested binaries before the app, submits for notarization, staples and validates the app and DMG
It uses Apple's hdiutil and does not need a Developer ID Installer certificate
Override `COMPONENT_SIGNING_IDENTITY`, `COMPONENT_NOTARY_PROFILE` or `COMPONENT_OUTPUT_DIR` as needed
Changing the signing team also requires updating the XPC and temperature-reader requirements
Generated archives and credentials stay outside the repository

For an offline test build, run `scripts/release_embedded_component_test.sh /path/to/FanControl-Component-1.7.zip`
This archives the main app with the temporary embedded resource, exports Developer ID signing with a distribution provisioning profile, unpacks the component into Contents/Helpers, re-signs the outer app preserving distribution entitlements, notarizes and staples the result
It removes the temporary resource when finished
The original release script remains unchanged
The embedded test build is not an App Store submission artifact
An App Store release still needs a separately distributed component and review of that architecture
No release is published by either script

The XCTest target uses fake fan hardware and never writes to the SMC
It covers malformed commands, ownership, disconnect restoration, heartbeat expiry, partial write failures, update interlocks secure cross-process snapshot coding and concurrent/cancelled XPC completion
Full installation, approved system-daemon connectivity, real fan writes and uninstall/update behavior must also be verified on a Mac through the installation steps

## App Review

The sandboxed app requests a temporary Mach lookup exception for the component service
Explain the complete companion architecture and provide the component to App Review
A successful build, notarization or sandbox connection does not establish App Store acceptance
Apple's additional-code and privilege-escalation rules still require review of this arrangement

References

- https://developer.apple.com/documentation/servicemanagement/smappservice
- https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html
- https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility

The installer is unpacked at release time because executable files extracted at runtime by the sandbox receive a quarantine flag that prevents launch
The runtime never removes quarantine attributes or disables Gatekeeper

After copying and verifying its installed bundle, the unsandboxed installer starts that bundle executable with Process and exits
Using LaunchServices for this second launch causes App Translocation mount conflicts (OSStatus -47) for downloaded apps
The first launch from the sandboxed main app still uses LaunchServices, and quarantine attributes remain intact
