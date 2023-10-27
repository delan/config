#!/bin/sh
PATH=/run/current-system/sw/bin
# printf '<%s> ' | logger -f /dev/stdin
< /var/lib/acme/colo.daz.cat/fullchain.pem ssh delan@stratus.daz.cat \
    'sudo tee /etc/apache2/.local/fullchain.pem > /dev/null'
< /var/lib/acme/colo.daz.cat/key.pem ssh delan@stratus.daz.cat \
    'sudo tee /etc/apache2/.local/key.pem > /dev/null'
ssh delan@stratus.daz.cat 'cd /etc/apache2/.local; sudo cat fullchain.pem dhparam ecparam | sudo tee fullchain+dhparam+ecparam.pem > /dev/null'
ssh delan@stratus.daz.cat sudo systemctl reload apache2
