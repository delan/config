{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.programs = {
    wireshark = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkIf cfg.programs.wireshark {
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    users.users."${config.internal.initialUser}".extraGroups = [ "wireshark" ];
  };
}
