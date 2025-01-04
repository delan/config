#!/bin/sh
set -eu
export PATH=/run/current-system/sw/bin:$PATH

size=$(zpool get -Hpo value size ocean)
free=$(zpool get -Hpo value free ocean)
echo $((size / 1024)) $((free / 1024))
