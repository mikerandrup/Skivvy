#!/bin/zsh
# Shared paths for the Skivvy scripts. Source, do not run.
SKIVVY_ROOT="${0:A:h:h}"
SKIVVY_PROJECT="$SKIVVY_ROOT/Skivvy/Skivvy.xcodeproj"
SKIVVY_PACKAGE="$SKIVVY_ROOT/Skivvy/SkivvyCore"
SKIVVY_SCHEME="Skivvy"
SKIVVY_BUNDLE_ID="com.metroplexweb.Skivvy"
SKIVVY_DEST="platform=macOS,arch=arm64"

skivvy_app_path() {
  local config="${1:-Debug}"
  xcodebuild -project "$SKIVVY_PROJECT" -scheme "$SKIVVY_SCHEME" \
    -configuration "$config" -showBuildSettings 2>/dev/null \
    | awk '/ CODESIGNING_FOLDER_PATH =/{print $3}'
}
