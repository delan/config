#!/bin/sh
set -eu
exec rsync -a --no-i-r --info=progress2 "$@"
