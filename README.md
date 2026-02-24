# FanControl

Controls fan speed using a privileged helper for secure SMC write access

## Warning

When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment
