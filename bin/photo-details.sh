#!/usr/bin/env zsh
set -eu
for i; do
    exiftool -p '<small>$Model + $LensID</small>' -- "$i"
    exiftool -p '<small>ISO $ISO, $FocalLength, f/$Aperture, $ExposureTime</small>' -- "$i"
done
