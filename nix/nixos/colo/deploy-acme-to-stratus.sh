#!/bin/sh
PATH=/run/current-system/sw/bin
cd /var/lib/acme/colo.daz.cat
scp fullchain.pem key.pem acme_@stratus.daz.cat:
ssh acme_@stratus.daz.cat doas /root/deploy-acme.sh
