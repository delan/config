#!/usr/bin/env zsh
# usage: wine.sh <prefix_name> <command ...>                (to run `wine command ...`)
#        wine.sh <prefix_name> -<command> <args ...>        (to run `command args ...`)
set -euo pipefail

prefix_name=$1; shift
command=$1; shift
export WINEPREFIX=~/opt/$prefix_name/wine

case "$command" in
    (-*) "${command#-}" "$@" ;;
    (*) wine "$command" "$@" ;;
esac
