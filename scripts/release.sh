#!/usr/bin/env bash
# Build, sign, notarize, and package OCS for direct distribution.
# Output: build/OCS-<version>.dmg, ready to host.
#
# Prereqs:
#   - Developer ID Application cert in login keychain
#   - notarytool keychain profile named "ocs-notary"
#     (xcrun notarytool store-credentials ocs-notary --apple-id ... --team-id ... --password ...)

set -euo pipefail

SCHEME="OCS"
CONFIGURATION="Release"
TEAM_ID="PXZ4MFS7T9"
NOTARY_PROFILE="ocs-notary"
APP_NAME="OptCmdSpace"

BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/OCS.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$BUILD_DIR/exportOptions.plist"
APP_PATH="$EXPORT_DIR/$APP_NAME.app"

VERSION=$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null \
  | awk '/[^_]MARKETING_VERSION =/ { print $3; exit }')
if [ -z "${VERSION:-}" ]; then
  echo "error: could not read MARKETING_VERSION from xcodebuild settings" >&2
  exit 1
fi
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

IDENTITY=$(security find-identity -v -p codesigning \
  | awk -F'"' '/Developer ID Application/ { print $2; exit }')
if [ -z "${IDENTITY:-}" ]; then
  echo "error: no Developer ID Application identity found in login keychain" >&2
  exit 1
fi

echo "==> identity: $IDENTITY"
echo "==> version:  $VERSION"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF

echo "==> archiving"
xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" -destination 'generic/platform=macOS' archive

echo "==> exporting"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR"

echo "==> notarizing app"
APP_ZIP="$BUILD_DIR/$APP_NAME.zip"
ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"
xcrun notarytool submit "$APP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
rm "$APP_ZIP"

echo "==> stapling app"
xcrun stapler staple "$APP_PATH"

echo "==> building DMG"
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_STAGING"

echo "==> signing DMG"
codesign --sign "$IDENTITY" --timestamp "$DMG_PATH"

echo "==> notarizing DMG"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> stapling DMG"
xcrun stapler staple "$DMG_PATH"

echo "==> verifying"
spctl --assess --verbose=4 --type execute "$APP_PATH"
spctl --assess --verbose=4 --type open --context context:primary-signature "$DMG_PATH"
xcrun stapler validate "$APP_PATH"
xcrun stapler validate "$DMG_PATH"

echo ""
echo "done: $DMG_PATH"
