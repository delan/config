#!/usr/bin/env zsh
# usage: $0 [dataset regex]
set -euo pipefail
dataset_regex=${1-}

zfs list -Ho name -t snapshot \
| rg '@[0-9]{4,}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z$' \
| rg -o '^[^@]+' \
| rg -- "$dataset_regex" \
| sort -u
