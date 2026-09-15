#!/bin/zsh
# Quit any running Skivvy, build Debug, launch via LaunchServices
# so Skivvy is its own TCC responsible process.
set -e
source "${0:A:h}/common.sh"
pkill -x Skivvy 2>/dev/null || true
"${0:A:h}/build.sh" Debug
APP="$(skivvy_app_path Debug)"
open -a "$APP"
sleep 1
pgrep -x Skivvy >/dev/null && echo "Skivvy running (pid $(pgrep -x Skivvy))"
