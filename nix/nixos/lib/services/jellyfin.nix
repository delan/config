{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.services = {
    jellyfin = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal.services;
  in mkIf cfg.jellyfin {
    users.users.jellyfin = {
      uid = 8096;
    };

    networking.firewall.allowedTCPPorts = [ 8096 ];

    environment.systemPackages = with pkgs; [
      docker-compose

      # for ocean
      nfsUtils
    ];
  };
}
