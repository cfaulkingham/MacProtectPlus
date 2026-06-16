#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE="${MACPROTECTPLUS_APP_BUNDLE:-$HOME/Applications/MacProtectPlus.app}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_APP_BUNDLE="$ROOT_DIR/dist/MacProtectPlus.app"
OLD_SYSTEM_APP_BUNDLE="/Applications/MacProtectPlus.app"
USER_WORKFLOW="${MACPROTECTPLUS_USER_WORKFLOW:-$HOME/Library/Services/MacProtectPlus.workflow}"
USER_WORKFLOW_BY_NAME="${MACPROTECTPLUS_USER_WORKFLOW_BY_NAME:-$HOME/Library/Services/Protect as DMG.workflow}"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

/usr/bin/pkill -x MacProtectPlus >/dev/null 2>&1 || true

if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -u "$APP_BUNDLE" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$DEV_APP_BUNDLE" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$OLD_SYSTEM_APP_BUNDLE" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$USER_WORKFLOW" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$USER_WORKFLOW_BY_NAME" >/dev/null 2>&1 || true
fi

/bin/rm -rf "$APP_BUNDLE" "$USER_WORKFLOW" "$USER_WORKFLOW_BY_NAME"

/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -update English >/dev/null 2>&1 || true
/usr/bin/killall Finder >/dev/null 2>&1 || true

echo "MacProtectPlus was uninstalled for the current user."
