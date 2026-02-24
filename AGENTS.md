# Repository Guidelines

## Project Structure & Module Organization
- `FanControl/` holds the SwiftUI app sources. Key files include `ContentView.swift` (UI), `FanVM.swift` (view model), and `SMCService.swift` (SMC service wrapper)
- `Shared/` contains shared models and SMC access (`Fan.swift`, `SMCClient.swift`, `FanControlXPC.swift`) used by both the app and the helper
- `FanControlHelper/` is the privileged helper target (XPC listener entry in `main.swift`)
- `FanControl/LaunchDaemons/` contains the launchd plist for SMAppService (`dev.topscrech.FanControl.helper.plist`)
- `FanControl/Assets.xcassets` stores app assets/icons
- `FanControl.xcodeproj` is the Xcode project. There is no separate test target or `Tests/` directory in the repo

## Build, Test, and Development Commands
- Build (Debug): `xcodebuild -project FanControl.xcodeproj -scheme FanControl -configuration Debug build`
- Build (Release): `xcodebuild -project FanControl.xcodeproj -scheme FanControl -configuration Release build`
- Run locally: open `FanControl.xcodeproj` in Xcode and use Product -> Run. CLI runs can use the built `.app` in DerivedData
- Tests: no test target is configured yet; add one in Xcode before using `xcodebuild test`

## Free Distribution Export (Outside App Store)
- Use this faster CLI-first flow for free distribution to users outside the Mac App Store
- Archive once with `Release` and `generic/platform=macOS` to a known path, for example `~/Downloads/FanControl.xcarchive`
- Skip Organizer export and take the app from `FanControl.xcarchive/Products/Applications/FanControl.app`
- Copy the app to a working path, for example `~/Downloads/FanControl.app`, before re-signing
- Re-sign `Contents/Library/PrivilegedHelperTools/FanControlHelper` first, then `FanControl.app`, with `Developer ID Application`
- Keep helper identifier as `dev.topscrech.FanControl.helper` when re-signing
- Verify with `codesign --verify --deep --strict --verbose=2` and `spctl -a -vv`
- Zip with `ditto -c -k --keepParent FanControl.app v0_2_0.zip`, using the current project version in the filename format `vX_Y_Z.zip`
- Publish the zip with `gh release create` or `gh release upload` when shipping via GitHub releases, and ensure the uploaded file name matches the current project version format (for example `v0_2_0.zip`)
- Cleanup after packaging by deleting `FanControl.xcarchive` and other temporary export artifacts
- Notarization is optional for ad-hoc sharing, required for best Gatekeeper compatibility on other Macs

## Coding Style & Naming Conventions
- Swift standard style: 4-space indentation, braces on the same line, trailing commas allowed in multi-line literals
- Naming: `UpperCamelCase` for types (structs/classes/enums), `lowerCamelCase` for methods and properties, enum cases in `lowerCamelCase`
- Keep UI updates on the main actor (`@Observable`, `@MainActor`) and keep SMC access isolated in `SMCClient`
- No formatter or linter is configured; match existing file formatting

## Testing Guidelines
- Current state: no automated tests
- If adding tests, create an Xcode test target (e.g., `FanControlTests`) and use `XCTest` with files named `SomethingTests.swift`
- Prefer unit tests for SMC parsing and view-model logic; avoid hardware writes in tests

## Commit & Pull Request Guidelines
- Commit messages are short, lowercase summaries (often comma-separated lists). Example: `logging & no longer resetting errorMessage`
- Keep commits focused and descriptive; avoid large mixed changes
- PRs should include: brief description, how you tested, and screenshots for UI changes. Link issues if applicable

## Security & Configuration Notes
- SMC writes require elevated privileges. Manual fan control uses a privileged helper registered via `SMAppService`
- The helper is installed from `FanControl/LaunchDaemons` and runs as root; keep the Mach service name in `Shared/FanControlXPC.swift` in sync with the plist
- Avoid committing local paths, DerivedData artifacts, or credentials
