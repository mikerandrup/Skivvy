#!/bin/zsh
# Stream Skivvy's unified log. Usage: Shell/logs.sh [--last 5m]
exec /usr/bin/log ${1:+show} "$@" --predicate 'subsystem == "com.metroplexweb.Skivvy"' --style compact --info
