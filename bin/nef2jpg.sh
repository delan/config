#!/bin/sh
# Co-authored-by: the6p4c <me@doggirl.gay>
set -eu
if [ $# -lt 1 ]; then
    >&2 echo "usage: $0 <input> [input ...]"
    exit 1
fi
for input in "$@"; do
    >&2 echo ">>> $input"
    exiftool -b -JpgFromRaw "$input" > "${input%.NEF}.JpgFromRaw.jpg"
done
