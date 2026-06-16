#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE="${MACPROTECTPLUS_APP_BUNDLE:-$HOME/Applications/MacProtectPlus.app}"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [ ! -d "$APP_BUNDLE" ]; then
  cat >&2 <<MESSAGE
$APP_BUNDLE is not installed.
Build and install with the installer manager first:

  ./script/build_installer.sh
  open "dist/MacProtectPlus Installer.app"

MESSAGE
  exit 1
fi

"$LSREGISTER" -u "/Applications/MacProtectPlus.app" >/dev/null 2>&1 || true
"$LSREGISTER" -f "$APP_BUNDLE" >/dev/null 2>&1 || true

/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -update English >/dev/null 2>&1 || true
/usr/bin/killall Finder >/dev/null 2>&1 || true

echo "Registered MacProtectPlus. In Finder, right-click selected files and use Protect as DMG."
