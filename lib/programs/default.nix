{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ./wireshark.nix
  ];
}
