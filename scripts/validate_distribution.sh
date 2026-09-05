#!/usr/bin/env bash
set -euo pipefail
APP="${1:?Pass the exported app}"
OUTPUT="${2:?Pass the validation output directory}"
mkdir -p "$OUTPUT"
codesign -d --entitlements :- "$APP" > "$OUTPUT/entitlements.plist" 2>/dev/null
security cms -D -i "$APP/Contents/embedded.provisionprofile" > "$OUTPUT/profile.plist"
/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$OUTPUT/entitlements.plist" | grep -qx true
/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.icloud-container-environment' "$OUTPUT/entitlements.plist" | grep -qx Production
/usr/libexec/PlistBuddy -c 'Print :ProvisionsAllDevices' "$OUTPUT/profile.plist" | grep -qx true
if /usr/libexec/PlistBuddy -c 'Print :com.apple.security.get-task-allow' "$OUTPUT/entitlements.plist" 2>/dev/null | grep -qx true; then
    echo 'Distribution must not allow debugger attachment'; exit 1
fi
for executable in \
    "$APP/Contents/MacOS/FanControl" \
    "$APP/Contents/Helpers/FanControl Component.app/Contents/MacOS/FanControl Component" \
    "$APP/Contents/Helpers/FanControl Component.app/Contents/Library/PrivilegedHelperTools/FanControlHelper" \
    "$APP/Contents/Helpers/FanControl Component.app/Contents/Library/PrivilegedHelperTools/iSMC"; do
    architectures="$(lipo -archs "$executable")"
    for required in arm64 x86_64; do
        case " $architectures " in
            *" $required "*) ;;
            *) echo "Missing $required architecture: $executable"; exit 1 ;;
        esac
    done
    codesign --verify --strict --all-architectures "$executable"
done
printf '%s\n' 'Sandbox enabled, Production CloudKit, all-device provisioning, no get-task-allow, universal binaries and valid nested signatures' > "$OUTPUT/validation.txt"
