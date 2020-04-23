{ config, lib, options, modulesPath, pkgs }: with lib; {
  options.internal.services = {
    jackett = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal.services;
  in mkIf cfg.jackett {
    services.jackett = {
      enable = true;
      openFirewall = true;
    };
  };
}
