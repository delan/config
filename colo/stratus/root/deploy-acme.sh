#!/bin/sh
set -eu

cd /etc/apache2/.local
cp ~acme_/fullchain.pem fullchain.pem
cp ~acme_/key.pem key.pem
cat fullchain.pem dhparam ecparam > fullchain+dhparam+ecparam.pem
systemctl reload apache2
