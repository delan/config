#!/usr/bin/env zsh
# usage: restart-plex.sh
set -xeu
sudo systemctl stop podman-plex.service
sudo systemctl restart ocean.mount ocean-active.mount
sudo systemctl start podman-plex.service
