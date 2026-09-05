#!/usr/bin/env bash
# Based on release_fancontrol.sh: Developer ID signing, AC_NOTARY, archive and notarization
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="FanControl Component"
IDENTITY="${COMPONENT_SIGNING_IDENTITY:-Developer ID Application: Sergei Saliukov (8FQUA2F388)}"
NOTARY_PROFILE="${COMPONENT_NOTARY_PROFILE:-AC_NOTARY}"
OUTPUT_DIR="${COMPONENT_OUTPUT_DIR:-$HOME/Downloads/FanControlComponent-$(date +%Y%m%d-%H%M%S)}"
VERSION="$(sed -n 's/.*static let version = "\([^"]*\)".*/\1/p' "$PROJECT_DIR/Shared/Component/ComponentConfiguration.swift")"

xcodebuild -version >/dev/null
if [[ -z "$VERSION" ]]; then echo "Missing component version"; exit 1; fi
if ! security find-identity -v -p codesigning | /usr/bin/grep -F -- "$IDENTITY" >/dev/null; then
    echo "Developer ID Application identity is unavailable: $IDENTITY"
    exit 1
fi
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null
mkdir -p "$OUTPUT_DIR"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/FanControlComponentRelease.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
ARCHIVE="$WORK_DIR/Component.xcarchive"
APP="$OUTPUT_DIR/FanControl Component.app"
DMG="$OUTPUT_DIR/FanControl-Component-$VERSION.dmg"
if [[ -e "$APP" || -e "$DMG" ]]; then
    echo "Output already exists — choose a new COMPONENT_OUTPUT_DIR"
    exit 1
fi

submit_and_wait() {
    local file="$1" submission submission_id result status
    submission="$(xcrun notarytool submit "$file" --keychain-profile "$NOTARY_PROFILE" --no-wait --output-format json)"
    submission_id="$(printf '%s' "$submission" | plutil -extract id raw -o - -- -)"
    printf '%s\n' "$submission" > "$file.notary-submission.json"
    echo "Notarization submission: $submission_id"
    result="$(xcrun notarytool wait "$submission_id" --keychain-profile "$NOTARY_PROFILE" --timeout 30m --output-format json)"
    printf '%s\n' "$result" > "$file.notary-result.json"
    status="$(printf '%s' "$result" | plutil -extract status raw -o - -- -)"
    if [[ "$status" != "Accepted" ]]; then
        xcrun notarytool log "$submission_id" --keychain-profile "$NOTARY_PROFILE"
        exit 1
    fi
}

xcodebuild -project "$PROJECT_DIR/FanControl.xcodeproj" -scheme "$SCHEME" \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath "$WORK_DIR/DerivedData" archive -archivePath "$ARCHIVE" \
    CODE_SIGNING_ALLOWED=NO MARKETING_VERSION="$VERSION"
ditto "$ARCHIVE/Products/Applications/FanControl Component.app" "$APP"

for relative in 'Contents/Resources/iSMC' 'Contents/Library/PrivilegedHelperTools/iSMC'; do
    codesign --force --timestamp --options runtime --sign "$IDENTITY" \
        --identifier dev.topscrech.FanControl.ismc "$APP/$relative"
done
codesign --force --timestamp --options runtime --sign "$IDENTITY" \
    --identifier dev.topscrech.FanControl.helper "$APP/Contents/Library/PrivilegedHelperTools/FanControlHelper"
codesign --force --timestamp --options runtime --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
ZIP="$OUTPUT_DIR/FanControl-Component-$VERSION.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
submit_and_wait "$ZIP"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
# Recreate the ZIP with the stapled app
rm "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
mkdir "$WORK_DIR/DMG"
ditto "$APP" "$WORK_DIR/DMG/FanControl Component.app"
# The component now installs itself when opened
cp "$PROJECT_DIR/docs/Component Installation.txt" "$WORK_DIR/DMG/Installation.txt"
hdiutil create -volname 'FanControl Component' -srcfolder "$WORK_DIR/DMG" -format UDZO "$DMG"
codesign --timestamp --sign "$IDENTITY" "$DMG"
submit_and_wait "$DMG"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type execute --verbose=2 "$APP"
shasum -a 256 "$DMG" > "$DMG.sha256"
printf 'Signed app: %s\nNotarized DMG: %s\n' "$APP" "$DMG"
