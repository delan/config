{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.services = {
    samba = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkIf cfg.services.samba {
    services.samba = {
      enable = true;
      extraConfig = ''
        syslog = 3
        map to guest = Bad User
        guest account = nobody
      '';
      shares = {
        scanner = {
          path = "/home/scanner";
          "guest ok" = "yes";
          "read only" = "no";
          "force user" = "nobody";
          "force group" = "nogroup";
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 139 445 ];
      allowedUDPPorts = [ 137 138 ];
    };
  };
}
