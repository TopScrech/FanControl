# Repository Guidelines

## Project Structure & Module Organization
- `FanControl/` holds the SwiftUI app sources. Key files include `ContentView.swift` (UI), `FanVM.swift` (view model), and `SMCService.swift` (SMC service wrapper)
- `Shared/` contains shared models and SMC access (`Fan.swift`, `SMCClient.swift`, `FanControlXPC.swift`) used by both the app and the helper
- `FanControlHelper/` is the privileged helper target (XPC listener entry in `main.swift`)
- `FanControl/LaunchDaemons/` contains the launchd plist for SMAppService (`dev.topscrech.FanControl.helper.plist`)
- `FanControl/Assets.xcassets` stores app assets/icons
- `FanControl.xcodeproj` is the Xcode project. There is no separate test target or `Tests/` directory in the repo

## Coding Style & Naming Conventions
- Swift standard style: 4-space indentation, braces on the same line, trailing commas allowed in multi-line literals
- Naming: `UpperCamelCase` for types (structs/classes/enums), `lowerCamelCase` for methods and properties, enum cases in `lowerCamelCase`
- Keep UI updates on the main actor (`@Observable`, `@MainActor`) and keep SMC access isolated in `SMCClient`
- No formatter or linter is configured; match existing file formatting

## Testing Guidelines
- Current state: no automated tests
- If adding tests, create an Xcode test target (e.g., `FanControlTests`) and use `XCTest` with files named `SomethingTests.swift`
- Prefer unit tests for SMC parsing and VM logic; avoid hardware writes in tests

## Security & Configuration Notes
- SMC writes require elevated privileges. Manual fan control uses a privileged helper registered via `SMAppService`
- The helper is installed from `FanControl/LaunchDaemons` and runs as root; keep the Mach service name in `Shared/FanControlXPC.swift` in sync with the plist
- Avoid committing local paths, DerivedData artifacts, or credentials
