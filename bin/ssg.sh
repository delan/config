#!/usr/bin/env zsh
set -euo pipefail

cd ~/opt/ssg
WINEPREFIX=${WINEPREFIX-$(pwd)/wine} wine ${1-ssgwin32}
