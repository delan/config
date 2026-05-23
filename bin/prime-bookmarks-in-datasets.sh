#!/usr/bin/env zsh
# usage: $0 <dataset ...>
set -euo pipefail

for dataset; do
    zfs list -Ho name -d 1 -t snapshot "$dataset" \
    | while read -r ds_snap; do
        ds_bookmark=$(printf \%s\\n "$ds_snap" | sed 's/@/#/')
        echo ">>> sudo zfs bookmark $ds_snap $ds_bookmark"
        sudo zfs bookmark "$ds_snap" "$ds_bookmark" || :
    done
done
