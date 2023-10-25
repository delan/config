#!/bin/sh
PATH=/run/current-system/sw/bin
# printf '<%s> ' | logger -f /dev/stdin
< /var/lib/acme/colo.daz.cat/fullchain.pem ssh delan@opacus.daz.cat \
    'doas tee /etc/ssl/private/opacus.daz.cat.both > /dev/null'
< /var/lib/acme/colo.daz.cat/key.pem ssh delan@opacus.daz.cat \
    'doas tee /etc/ssl/private/opacus.daz.cat.key > /dev/null'
< /var/lib/acme/colo.daz.cat/full.pem ssh delan@opacus.daz.cat \
    'tee /home/delan/.znc/znc.pem > /dev/null'
ssh delan@opacus.daz.cat doas rcctl restart smtpd
