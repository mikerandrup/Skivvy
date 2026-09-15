#!/bin/zsh
# Build Release and install to /Applications, replacing any
# existing copy atomically, then launch the installed app.
set -e
source "${0:A:h}/common.sh"
pkill -x Skivvy 2>/dev/null || true
"${0:A:h}/build.sh" Release
APP="$(skivvy_app_path Release)"
DEST="/Applications/Skivvy.app"
STAGE="/Applications/.Skivvy.app.staging"
rm -rf "$STAGE"
ditto "$APP" "$STAGE"
rm -rf "$DEST"
mv "$STAGE" "$DEST"
open -a "$DEST"
sleep 1
echo "Installed and launched: $DEST"
