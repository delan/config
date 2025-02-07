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
        echo "$update" | jq -ec '[{"full_text": $x}] + .' --arg x "$(
            sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | tr \\n ' '
            sort -u /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | tr \\n ' '
	    < /proc/cpuinfo rg --pcre2 -o '(?<=^cpu MHz		: )[^.]*' | sort -g | sed q | tr \\n ' '
	    < /proc/cpuinfo rg --pcre2 -o '(?<=^cpu MHz		: )[^.]*' | sort -gr | sed q | tr \\n ' '
            printf ' '
            free -h | sed 2\!d | awk '{print $7}'
        )"
        printf ,
    done
}

i3status | f
