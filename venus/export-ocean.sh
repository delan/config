#!/usr/bin/env zsh
set -eux

cd /config/nix/nixos/venus
docker compose stop
sudo systemctl stop qbittorrent.service
sudo systemctl stop nfs-server.service
sudo systemctl stop samba-smbd.service
sudo zpool export ocean
