#!/usr/bin/env zsh
set -eux

cd /config/nix/nixos/venus
zpool list ocean || sudo zpool import ocean
docker compose start
# sudo systemctl start qbittorrent.service
sudo systemctl start nfs-server.service
sudo systemctl start samba-smbd.service
