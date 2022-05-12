{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    laptop = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkMerge [
    (mkIf cfg.laptop {
      services = {
        tlp.enable = true;

        logind.extraConfig = ''
          HandleLidSwitchExternalPower=ignore
        '';
      };

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
      };

      programs.light.enable = true;
      users.users."${config.internal.initialUser}".extraGroups = [ "video" ];
    })

    (mkIf (!cfg.laptop) {
      powerManagement.cpuFreqGovernor = "performance";
    })
  ];
}
