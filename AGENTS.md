#  Guidelines
- Always use the sui skill if available

## Security & Configuration Notes
- SMC writes require elevated privileges. Manual fan control uses a privileged helper registered via `SMAppService`
- The helper is installed from `FanControl/LaunchDaemons` and runs as root; keep the Mach service name in `Shared/FanControlXPC.swift` in sync with the plist
- Avoid committing local paths, DerivedData artifacts, or credentials
