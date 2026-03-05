# FanControl

Controls fan speed using a privileged helper for secure SMC write access

> [!WARNING]
> When switching from system fan mode to manual, the app tries to set fan speed every second for up to 15 seconds, since manual mode can only be applied after auto mode is set, which may take a moment

# Supported platforms
- macOS 14+

# Build command

Requires Xcode 26.4+ and access to a private CoreSMC library

Archive & save to Downloads
```
bash -lc 'set -euo pipefail; cd "/Users/topscrech/Library/Mobile Documents/com~apple~CloudDocs/Projects/App Store/FanControl"; ARCH="$HOME/Downloads/FanControl.xcarchive"; APP="$HOME/Downloads/FanControl.app"; xcodebuild -project "./FanControl.xcodeproj" -scheme "FanControl" -configuration Release -destination "generic/platform=macOS" archive -archivePath "$ARCH"; rm -rf "$APP"; cp -R "$ARCH/Products/Applications/FanControl.app" "$APP"; ZIP="$HOME/Downloads/v$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" | tr "." "_").zip"; rm -f "$ZIP"; ditto -c -k --keepParent "$APP" "$ZIP"; rm -rf "$ARCH"'
```
