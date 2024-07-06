#!/bin/sh
set -eu

doas cat /var/nsd/etc/nsd.conf > var/nsd/etc/nsd.conf
cp /var/nsd/zones/*.zone var/nsd/zones
cp /var/nsd/zones/*.serial var/nsd/zones
cp /var/nsd/zones/*.in var/nsd/zones
cp /var/nsd/zones/acme var/nsd/zones
cp /var/nsd/zones/acme-unlock var/nsd/zones
cp /var/nsd/zones/update-rdns.sh var/nsd/zones
