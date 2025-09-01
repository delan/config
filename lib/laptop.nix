{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    laptop = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkMerge [
    (mkIf cfg.laptop {
      services = {
        # conflicts with plasma5 and also is discouraged on modern amd?
        tlp.enable = false;

        # https://bugzilla.kernel.org/show_bug.cgi?id=198931
        # https://askubuntu.com/questions/1044127
        tlp.settings = { USB_BLACKLIST = "17ef:3082"; };

        logind.settings.Login = {
          HandleLidSwitchExternalPower = "ignore";
        };

        # Energy Performance Preference control for modern cpus
        # <https://wiki.archlinux.org/title/CPU_frequency_scaling#Autonomous_frequency_scaling>
        cpupower-gui.enable = true;
        auto-epp = {
          enable = true;
          settings.Settings = {
            # epp_state_for_AC = "balance_performance";  # same as firmware default
            epp_state_for_AC = "power";  # firmware default is balance_performance
            epp_state_for_BAT = "power";  # firmware default is balance_power
          };
        };
      };

      programs.light.enable = true;
      users.users."${config.internal.initialUser}".extraGroups = [ "video" ];
    })

    (mkIf (!cfg.laptop) {
      powerManagement.cpuFreqGovernor = "performance";
    })
  ];
}
