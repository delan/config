#!/usr/bin/env zsh
set -eu
SHUPPY_DARKTABLE_DIR=${SHUPPY_DARKTABLE_DIR-/ocean/private/delan/photos/darktable}
for i; do
    echo $SHUPPY_DARKTABLE_DIR/${i%%_*}_*/darktable_exported/$i
done
