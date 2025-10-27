#!/usr/bin/env zsh
set -eu
SHUPPY_DARKTABLE_DIR=${SHUPPY_DARKTABLE_DIR-/cuffs/darktable}
for i; do
    echo $SHUPPY_DARKTABLE_DIR/${i%%_*}_*/darktable_exported/$i
done
