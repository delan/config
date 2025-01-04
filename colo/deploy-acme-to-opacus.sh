#!/bin/sh
set -eu

PATH=/run/current-system/sw/bin
cd /var/lib/acme/colo.daz.cat
scp fullchain.pem key.pem full.pem acme_@opacus.daz.cat:
ssh acme_@opacus.daz.cat doas /root/deploy-acme.sh
