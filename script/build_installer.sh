#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacProtectPlus"
MANAGER_NAME="MacProtectPlus Installer"
MANAGER_PRODUCT="MacProtectPlusInstaller"
BUNDLE_ID="com.colinfaulkingham.MacProtectPlusInstaller"
VERSION="1.0"
MIN_SYSTEM_VERSION="13.0"
BUILD_CONFIGURATION="release"
CODESIGN_IDENTITY="${MACPROTECTPLUS_CODESIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
MANAGER_APP="$DIST_DIR/$MANAGER_NAME.app"
MANAGER_CONTENTS="$MANAGER_APP/Contents"
MANAGER_MACOS="$MANAGER_CONTENTS/MacOS"
MANAGER_RESOURCES="$MANAGER_CONTENTS/Resources"
MANAGER_INFO="$MANAGER_CONTENTS/Info.plist"
ZIPROOT="$DIST_DIR/installer-ziproot"
ZIP_PATH="$DIST_DIR/MacProtectPlus-Installer-$VERSION.zip"

MACPROTECTPLUS_BUILD_CONFIGURATION="$BUILD_CONFIGURATION" MACPROTECTPLUS_UNIVERSAL=1 "$ROOT_DIR/script/build_and_run.sh" --build-only

SWIFT_BUILD_ARGS=(-c "$BUILD_CONFIGURATION" --arch arm64 --arch x86_64)
swift build --product "$MANAGER_PRODUCT" "${SWIFT_BUILD_ARGS[@]}"

rm -rf "$MANAGER_APP" "$ZIPROOT" "$ZIP_PATH" "$DIST_DIR/$APP_NAME-$VERSION.pkg" "$DIST_DIR/pkgroot" "$DIST_DIR/pkg-scripts"

mkdir -p "$MANAGER_MACOS" "$MANAGER_RESOURCES/Payload"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$MANAGER_PRODUCT"
cp "$BUILD_BINARY" "$MANAGER_MACOS/$MANAGER_PRODUCT"
chmod +x "$MANAGER_MACOS/$MANAGER_PRODUCT"
cp "$ROOT_DIR/Assets/MacProtectPlus.icns" "$MANAGER_RESOURCES/MacProtectPlus.icns"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "$APP_BUNDLE" "$MANAGER_RESOURCES/Payload/MacProtectPlus.app"

cat >"$MANAGER_INFO" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$MANAGER_PRODUCT</string>
  <key>CFBundleIconFile</key>
  <string>MacProtectPlus</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$MANAGER_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/xattr -cr "$MANAGER_APP" 2>/dev/null || true
CODESIGN_ARGS=(--force --deep --sign "$CODESIGN_IDENTITY")
if [ "$CODESIGN_IDENTITY" != "-" ]; then
  CODESIGN_ARGS+=(--options runtime --timestamp)
fi
/usr/bin/codesign "${CODESIGN_ARGS[@]}" "$MANAGER_RESOURCES/Payload/MacProtectPlus.app" >/dev/null
/usr/bin/codesign "${CODESIGN_ARGS[@]}" "$MANAGER_APP" >/dev/null

echo "Built installer manager: $MANAGER_APP"

mkdir -p "$ZIPROOT"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "$MANAGER_APP" "$ZIPROOT/$MANAGER_NAME.app"
(
  cd "$ZIPROOT"
  COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc --keepParent "$MANAGER_NAME.app" "$ZIP_PATH"
)

echo "Built installer zip: $ZIP_PATH"
