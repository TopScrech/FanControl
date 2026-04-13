# FanControl

Control fan speed with ease on any Apple Silicon Mac

[**Download**](https://github.com/TopScrech/FanControl/releases/latest) • [**Website**](https://fancontrol.dev)

<img src="https://github.com/user-attachments/assets/e6a96188-47be-43f2-92d3-075ca72a10ab" width="300" alt="screenshot">
<br><br>

> [!WARNING]
> When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment

## Supported platforms
- macOS 14+

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

Other:
  -h, --help                    Show this help
  -r, --report                  Print support report
  -v, --version                 Print app version
  -d, --device                  Print device model
```

## Shortcuts
Option + left/right arrows - change selected fan
Command + 1 - Min mode
Command + 2 - Max mode
Command + 3 - Auto mode
Command + 4 - Open preset mode sheet

## Build

Requires Xcode 26.4+ and access to the private [CoreSMC](https://github.com/TopScrech/CoreSMC?tab=readme-ov-file) library

## Dependencies
4/5 libraries are developed and maintained by me, which helps minimize risk across every project where I use them

- [CoreSMC](https://github.com/TopScrech/CoreSMC) - private library for sending read/set fan speed calls via SMC
- [iSMC](https://github.com/dkorunic/iSMC) - Reading data from temperature sensors
- [AutoUpdate](https://github.com/TopScrech/AutoUpdate)
- [ScrechKit](https://github.com/TopScrech/TopScrech) - SwiftUI tweaks
- [LaunchAtLogin](https://github.com/TopScrech/LaunchAtLogin)

## Related links
- [Front-end](https://fancontrol.dev)
- [Front-end project](https://github.com/TopScrech/FanControl-dev)
