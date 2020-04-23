#!/bin/sh
set -eu

f() {
    read -r header
    echo "$header"
    jq -ecf ~/.config/i3/local.free.jq --stream --unbuffered | g
}

g() {
    printf \[
    while read -r update; do
        echo "$update" | jq -ec '[{"full_text": $x}] + .' --arg x "$(free -h | sed 2\!d | awk '{print $7}')"
        printf ,
    done
}

i3status | f
