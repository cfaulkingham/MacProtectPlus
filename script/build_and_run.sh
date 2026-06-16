#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MacProtectPlus"
BUNDLE_ID="com.colinfaulkingham.MacProtectPlus"
MIN_SYSTEM_VERSION="13.0"
BUILD_CONFIGURATION="${MACPROTECTPLUS_BUILD_CONFIGURATION:-debug}"
CODESIGN_IDENTITY="${MACPROTECTPLUS_CODESIGN_IDENTITY:--}"

SWIFT_BUILD_ARGS=(-c "$BUILD_CONFIGURATION")
if [ "${MACPROTECTPLUS_UNIVERSAL:-0}" = "1" ]; then
  SWIFT_BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ICON_FILE="$ROOT_DIR/Assets/MacProtectPlus.icns"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

build_bundle() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true

  if [ ! -f "$ICON_FILE" ]; then
    swift "$ROOT_DIR/script/generate_icon.swift" "$ICON_FILE"
  fi

  swift build "${SWIFT_BUILD_ARGS[@]}"
  BUILD_BINARY="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES"
  cp "$BUILD_BINARY" "$APP_BINARY"
  cp "$ICON_FILE" "$APP_RESOURCES/MacProtectPlus.icns"
  chmod +x "$APP_BINARY"

  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>Files and Folders</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.item</string>
      </array>
    </dict>
  </array>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>MacProtectPlus</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
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
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSMenuItem</key>
      <dict>
        <key>default</key>
        <string>Protect as DMG</string>
      </dict>
      <key>NSMessage</key>
      <string>protectFiles</string>
      <key>NSPortName</key>
      <string>$APP_NAME</string>
      <key>NSRequiredContext</key>
      <dict>
        <key>NSTextContent</key>
        <string>FilePath</string>
      </dict>
      <key>NSSendFileTypes</key>
      <array>
        <string>public.item</string>
      </array>
      <key>NSSendTypes</key>
      <array>
        <string>NSFilenamesPboardType</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

  CODESIGN_ARGS=(--force --deep --sign "$CODESIGN_IDENTITY")
  if [ "$CODESIGN_IDENTITY" != "-" ]; then
    CODESIGN_ARGS+=(--options runtime --timestamp)
  fi
  /usr/bin/codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE" >/dev/null
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    build_bundle
    open_app
    ;;
  --build-only|build)
    build_bundle
    ;;
  --debug|debug)
    build_bundle
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    build_bundle
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    build_bundle
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    build_bundle
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
