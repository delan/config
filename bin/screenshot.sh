#!/usr/bin/env zsh
set -euo pipefail

if [ $# -ge 2 ]; then
  sleep "$2"
fi

case "$1" in
  (all)
    maim | xclip -sel clip -t image/png
    ;;
  (primary)
    maim -g 2560x1440+0+0 | xclip -sel clip -t image/png
    ;;
  (window)
    maim -i $(xdotool getactivewindow) | xclip -sel clip -t image/png
    ;;
  (select)
    maim -s | xclip -sel clip -t image/png
    ;;
esac

notify-send -t 1000 screenshot 'copied to clipboard'
