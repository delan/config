#!/usr/bin/env zsh
set -eu
for i; do
    if [ "$(exiftool -api 'MissingTagValue=???' -f -p '$LensID' -- "$i")" != '???' ]; then
        exiftool -api 'MissingTagValue=???' -f -p '<small>$Make $Model + $LensID</small>' -- "$i"
    else
        exiftool -api 'MissingTagValue=???' -f -p '<small>$Make $Model + $LensInfo</small>' -- "$i"
    fi
    exiftool -p '<small>ISO $ISO, $FocalLength, f/$Aperture, $ExposureTime</small>' -- "$i"
done
