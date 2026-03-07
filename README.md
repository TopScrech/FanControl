# FanControl

Controls fan speed using a privileged helper for secure SMC write access

> [!WARNING]
> When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment

## Supported platforms
- macOS 14+

## Build

Requires Xcode 26.4+ and access to a private CoreSMC library

`iSMC` is bundled from `Vendor/iSMC/iSMC`, so users do not need to install it separately

## Related links
- [Front-end](https://fancontrol.dev)
- [Front-end project](https://github.com/TopScrech/FanControl-dev)
