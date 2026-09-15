#!/bin/zsh
# Build Skivvy. Usage: Shell/build.sh [Debug|Release]
set -e
source "${0:A:h}/common.sh"
CONFIG="${1:-Debug}"
xcodebuild -project "$SKIVVY_PROJECT" -scheme "$SKIVVY_SCHEME" \
  -configuration "$CONFIG" -destination "$SKIVVY_DEST" build \
  2>&1 | grep -E 'error:|warning:|BUILD ' | grep -v appintentsmetadata || true
echo "App: $(skivvy_app_path "$CONFIG")"
