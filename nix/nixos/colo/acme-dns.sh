#!/bin/sh
PATH=/run/current-system/sw/bin
# printf '<%s> ' | logger -f /dev/stdin
exec ssh acme_@opacus.daz.cat /var/nsd/zones/acme "$@"
