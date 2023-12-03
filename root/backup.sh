#!/bin/sh
set -eu

cp /var/nsd/etc/nsd.conf var/nsd/etc
cp /var/nsd/zones/*.zone var/nsd/zones
cp /var/nsd/zones/*.serial var/nsd/zones
cp /var/nsd/zones/*.in var/nsd/zones
cp /var/nsd/zones/acme var/nsd/zones
cp /var/nsd/zones/acme-unlock var/nsd/zones
