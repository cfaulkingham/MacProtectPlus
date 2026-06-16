#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacProtectPlus"
APP_SOURCE="$ROOT_DIR/dist/$APP_NAME.app"
APP_DEST="$HOME/Applications/$APP_NAME.app"
OLD_SYSTEM_APP_DEST="/Applications/$APP_NAME.app"
LEGACY_WORKFLOW_DEST="$HOME/Library/Services/MacProtectPlus.workflow"
LEGACY_WORKFLOW_NAME_DEST="$HOME/Library/Services/Protect as DMG.workflow"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

"$ROOT_DIR/script/build_and_run.sh" --build-only

mkdir -p "$(dirname "$APP_DEST")"

if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -u "$APP_DEST" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$OLD_SYSTEM_APP_DEST" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$LEGACY_WORKFLOW_DEST" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$LEGACY_WORKFLOW_NAME_DEST" >/dev/null 2>&1 || true
fi

rm -rf "$APP_DEST" "$LEGACY_WORKFLOW_DEST" "$LEGACY_WORKFLOW_NAME_DEST"

COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "$APP_SOURCE" "$APP_DEST"

if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "$APP_DEST" >/dev/null 2>&1 || true
fi

/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -update English >/dev/null 2>&1 || true
/usr/bin/killall Finder >/dev/null 2>&1 || true

echo "Installed $APP_DEST"
echo "Finder should show Protect as DMG for selected files."
