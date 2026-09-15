#!/bin/zsh
# Run the SkivvyCore unit and integration tests.
# The Accessibility integration suite self-skips unless the
# terminal running this script has the Accessibility grant.
set -e
source "${0:A:h}/common.sh"
cd "$SKIVVY_PACKAGE"
swift test "$@"
