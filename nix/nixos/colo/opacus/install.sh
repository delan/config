#!/bin/sh
set -eu

install -o root -g wheel -m 644 etc/doas.conf /etc/
install -o root -g wheel -m 755 root/deploy-acme.sh /root/
groupadd acme_ || :
useradd -md /home/acme_ -s /bin/sh -g acme_ acme_ || :
chmod 700 /home/acme_

# for acme-dns.sh
usermod -G _nsd acme_
