# FanControl

Control fan speed with ease on any Apple Silicon Mac

[**Download**](https://github.com/TopScrech/FanControl/releases/latest) • [**Website**](https://fancontrol.dev)

<img src="https://github.com/user-attachments/assets/e6a96188-47be-43f2-92d3-075ca72a10ab" width="300" alt="screenshot">
<br><br>

> [!WARNING]
> When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment

## Supported platforms
- macOS 14+

**FanControl Remote**
- iOS 17+
- visionOS 1+

## Remote control

The `FanControl Remote` iOS target uses the private CloudKit database shared with the macOS app, so it works across the internet and only for devices signed in to the same iCloud account

1. Create `iCloud.dev.topscrech.FanControl` in the Apple Developer portal
2. Associate the container with `dev.topscrech.FanControl` and `dev.topscrech.FanControl.remote`
3. Run both apps with the development environment once, then deploy the CloudKit schema to production before distribution
4. Enable **Allow control from iPhone** in the macOS app settings and keep FanControl running on the Mac

## CLI commands (fan)

```bash
Control all fans:
  min                           Set all fans to minimum
  max                           Set all fans to maximum
  -a, auto                      Set all fans to auto
  [speed]                       Set all fans to [speed, example: 4000, 4k, 1.6k]

Control a specific fan:
  -l, list                      List all fans
  -id [fan id] min              Set one fan to minimum
  -id [fan id] max              Set one fan to maximum
  -id [fan id] -a, auto         Set one fan to auto
  -id [fan id] [speed]          Set one fan to [speed]

Timers:
  timer [speed] [duration]      Run a timer for all fans, then return to auto
  -id [fan id] timer [speed] [duration]
                               Run a timer for one fan, then return to auto
  Duration: 30m, 1h, 1h30m, or 60s (maximum 23h59m)

Other:
  -h, --help                    Show this help
  -r, --report                  Print support report
  -v, --version                 Print app version
  -d, --device                  Print device model
```

For example, `fan timer 4k 30m` runs all fans at 4000 RPM for 30 minutes, clamped to each fan's supported range

Timers run in the foreground, independently of the app's timer UI, and return the selected fans to Auto on completion, Ctrl-C, termination, or terminal closure

## Shortcuts
- Option + left/right arrows - change selected fan
- Command + 1 - Min mode
- Command + 2 - Max mode
- Command + 3 - Auto mode
- Command + 4 - Open preset mode sheet

## Build

Requires Xcode 26.4+ and access to the private [CoreSMC](https://github.com/TopScrech/CoreSMC?tab=readme-ov-file) library

Run CLI parser and timer lifecycle tests with `python3 Tests/CLI/run-tests.py /path/to/CoreSMC`
The tests use a mock SMC service and keep build artifacts in a temporary directory

## Dependencies
4/5 libraries are developed and maintained by me, which helps minimize risk across all projects in which they are used

- [CoreSMC](https://github.com/TopScrech/CoreSMC) - private library for sending read/set fan speed calls via SMC
- [iSMC](https://github.com/dkorunic/iSMC) - Reading data from temperature sensors
- [AutoUpdate](https://github.com/TopScrech/AutoUpdate)
- [ScrechKit](https://github.com/TopScrech/TopScrech) - SwiftUI tweaks
- [LaunchAtLogin](https://github.com/TopScrech/LaunchAtLogin)
