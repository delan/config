#!/usr/bin/env zsh
set -euo pipefail

if ! [ -e ssgwin32.exe ]; then cd ~/opt/ssg; fi
WINEPREFIX=${WINEPREFIX-$(pwd)/wine} wine ${1-ssgwin32}
