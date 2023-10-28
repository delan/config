#!/bin/sh
set -eu

cp ~acme_/fullchain.pem /etc/ssl/private/opacus.daz.cat.both
cp ~acme_/key.pem /etc/ssl/private/opacus.daz.cat.key
cp ~acme_/full.pem ~delan/.znc/znc.pem
rcctl restart smtpd
