{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ./collectd.nix
    ./jackett.nix
    ./jellyfin.nix
  ];
}
