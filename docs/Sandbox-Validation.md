# Sandbox-2 validation

Validated on 2026-09-05 on an Apple Silicon Mac running macOS 27.0
Final component: 1.10, build 0, protocol 1

## Automated

- macOS app and universal component/helper builds succeed
- 19 hardware-free XCTest cases pass with zero failures
- Coverage includes invalid RPM/fan IDs, single ownership, lease expiry, partial writes, restoration retries, update write blocking, secure coding and racing/cancelled XPC replies
- Lifecycle coverage includes approval retry/timeout, the observed SMAppService EPERM-before-requiresApproval case, repeated registration, concurrent registration rejection, process-lock exclusion, version/build ordering and restoration failure preventing unregister
- Shell syntax and Git whitespace checks pass
- No simulator launched and no unit test writes to real hardware

## Final distribution artifact

`~/Downloads/FanControl-Sandbox-2/FanControl-signed.zip`

SHA-256:

```text
3460ecf5194b0f7c8cda7f92a56eaefbc7b8238f30e361a21df18f3c17ee0b57
```

- Component notarization: Accepted, `0d4c594d-8451-4751-a54c-75e3cc72fcd1`
- Main app notarization: Accepted, `411c9817-06d5-4686-9a8f-227fdec89462`
- Both apps are stapled and Gatekeeper accepts the final app as Notarized Developer ID
- Exported entitlements confirm App Sandbox, Production CloudKit and no get-task-allow
- Exported provisioning confirms ProvisionsAllDevices
- Main app, installer, daemon and temperature reader contain arm64 and x86_64 slices with valid signatures
- The main app contains both the component ZIP and the expanded signed installer in Contents/Helpers
- The release script removed its temporary source resource
- The original external release_fancontrol.sh remains unchanged

## Runtime observations

| Scenario | Evidence |
| --- | --- |
| Quarantined final package | Downloaded through Safari from a localhost HTTP server, with Safari-created quarantine metadata and a checksum matching the final ZIP |
| First launch | Normal macOS Open confirmation stated Apple checked the app; the app ran under App Translocation without clearing quarantine |
| Real update | The final package updated installed component 1.9 to 1.10 automatically and reconnected without a spurious app error alert |
| Root daemon | launchctl reported the component service running as root, PID 26724 |
| Same-version retry | Reinstalling 1.10 preserved PID 26724, returned to the ready UI and left no installer process running |
| Fan readings | Final app displayed both fan RPMs, including approximately 1,355 and 1,415 RPM under automatic control |
| Temperatures | Final app displayed CPU, GPU and battery readings, including approximately 77 °C, 57 °C and 33 °C |
| XPC allowlist | An unlisted ad-hoc-signed client was rejected in about 3 ms with NSCocoaErrorDomain 4097 |
| Manual and automatic commands | During this run, component 1.8's fan engine drove the fans to roughly 5,394/5,843 RPM and Auto returned them to 0 RPM; that engine implementation is unchanged in final component 1.10 |
| Recoverability | Prior complete signed component bundles remain retained under unique previous-*.app names |

The existing approval on this Mac was preserved
The observed permission-state regression from an intermediate replacement was fixed and covered by a regression test; the final replacement completed automatically

## External acceptance still required

- A fresh regular Mac without Xcode, an installed component or previous background approval
- The complete first-time approval pending/granted flow on that Mac
- Intel runtime behavior, beyond universal build validation
- Physical lease-expiry/disconnect restoration and updates while manual control is active; these are covered with fake hardware, not exercised on the real Mac in this run
- Production external-component delivery and App Store acceptance

These remaining scenarios are not implied by notarization or by the runtime checks on this already-configured Mac
