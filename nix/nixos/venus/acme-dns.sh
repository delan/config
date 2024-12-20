#!/bin/sh
# this runs as acme, but postRun runs as root
PATH=/run/current-system/sw/bin
# printf '<%s> ' | logger -f /dev/stdin
exec ssh acme_@opacus.daz.cat /var/nsd/zones/acme acme.daz.cat "$@"
