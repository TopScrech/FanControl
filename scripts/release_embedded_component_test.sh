#!/usr/bin/env bash
# Developer ID test distribution only — embeds components outside the App Store flow
# Based on release_fancontrol.sh and its existing signing/notarization configuration
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPONENT_ZIP="${1:?Pass the signed and stapled component ZIP from release_component.sh}"
OUTPUT_DIR="${TEST_OUTPUT_DIR:-$HOME/Downloads/FanControl-Sandbox-2-$(date +%Y%m%d-%H%M%S)}"
NOTARY_PROFILE="${COMPONENT_NOTARY_PROFILE:-AC_NOTARY}"
RESOURCE="$PROJECT_DIR/FanControl/Resources/FanControl-Component.zip"
if [[ -e "$RESOURCE" ]]; then echo "An embedded archive already exists: $RESOURCE"; exit 1; fi
if [[ -e "$OUTPUT_DIR" ]]; then echo "Choose a new output directory"; exit 1; fi
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/FanControlEmbeddedRelease.XXXXXX")"
trap 'rm -f "$RESOURCE"; rm -rf "$WORK_DIR"' EXIT
mkdir -p "$(dirname "$RESOURCE")" "$OUTPUT_DIR"
cp "$COMPONENT_ZIP" "$RESOURCE"
cat > "$WORK_DIR/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>developer-id</string>
<key>signingStyle</key><string>automatic</string>
<key>teamID</key><string>8FQUA2F388</string>
<key>destination</key><string>export</string>
</dict></plist>
PLIST
xcodebuild -project "$PROJECT_DIR/FanControl.xcodeproj" -scheme FanControl \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath "${TEST_DERIVED_DATA:-$WORK_DIR/DerivedData}" \
    archive -archivePath "$WORK_DIR/FanControl.xcarchive" -allowProvisioningUpdates ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO
xcodebuild -exportArchive -archivePath "$WORK_DIR/FanControl.xcarchive" \
    -exportOptionsPlist "$WORK_DIR/ExportOptions.plist" -exportPath "$OUTPUT_DIR" -allowProvisioningUpdates
APP="$OUTPUT_DIR/FanControl.app"
ZIP="$OUTPUT_DIR/FanControl-signed.zip"
test -f "$APP/Contents/Resources/FanControl-Component.zip"
# Expand before signing the outer app, never from inside the runtime sandbox
# Contents/Helpers is a nested-code location covered by the outer app signature
mkdir -p "$APP/Contents/Helpers"
ditto -x -k "$COMPONENT_ZIP" "$APP/Contents/Helpers"
codesign --verify --deep --strict -R '=anchor apple generic and certificate leaf[subject.OU] = "8FQUA2F388" and identifier "dev.topscrech.FanControl.component"' "$APP/Contents/Helpers/FanControl Component.app"
codesign --force --timestamp --options runtime --preserve-metadata=entitlements,requirements,flags \
    --sign "${COMPONENT_SIGNING_IDENTITY:-Developer ID Application: Sergei Saliukov (8FQUA2F388)}" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
"$PROJECT_DIR/scripts/validate_distribution.sh" "$APP" "$OUTPUT_DIR"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait --timeout 30m --output-format json > "$OUTPUT_DIR/notarization.json"
STATUS="$(plutil -extract status raw -o - "$OUTPUT_DIR/notarization.json")"
if [[ "$STATUS" != Accepted ]]; then cat "$OUTPUT_DIR/notarization.json"; exit 1; fi
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
rm "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose=2 "$APP"
shasum -a 256 "$ZIP" > "$ZIP.sha256"
printf 'Signed test app with embedded components: %s\n' "$ZIP"
