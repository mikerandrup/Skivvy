#!/bin/zsh
# Clear Skivvy's Accessibility grant so the prompt appears again.
source "${0:A:h}/common.sh"
tccutil reset Accessibility "$SKIVVY_BUNDLE_ID"
