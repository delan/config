#!/usr/bin/env zsh
# usage: $0 [dataset regex]
set -euo pipefail

list-datasets-with-timed-snapshots.sh "$@" \
| while read -r ds; do
    echo ">>> $ds"
    sudo zfs-thin-snapshots "$ds" || :
done
