# FanControl

Controls fan speed using a privileged helper for secure SMC write access

<img src="https://github.com/user-attachments/assets/e6a96188-47be-43f2-92d3-075ca72a10ab" width="300" alt="screenshot">

> [!WARNING]
> When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment

## Supported platforms
- macOS 14+

## Build

Requires Xcode 26.4+ and access to the private [CoreSMC](https://github.com/TopScrech/CoreSMC?tab=readme-ov-file) library

## Dependencies
4/5 libraries are developed and maintained by me, which helps minimize risk across every project where I use them

- [CoreSMC](https://github.com/TopScrech/CoreSMC) - private library for sending read/set fan speed calls via SMC
- [iSMC](https://github.com/dkorunic/iSMC) - Reading data from temperature sensor
- [AutoUpdate](https://github.com/TopScrech/AutoUpdate)
- [ScrechKit](https://github.com/TopScrech/TopScrech) - SwiftUI tweaks
- [LaunchAtLogin](https://github.com/TopScrech/LaunchAtLogin)

## Related links
- [Front-end](https://fancontrol.dev)
- [Front-end project](https://github.com/TopScrech/FanControl-dev)
