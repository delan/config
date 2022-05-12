{ config, lib, options, modulesPath, pkgs, ... }:
let dpi = 192;
in with lib; {
  config.services.xserver.dpi = dpi;
###   options.services.xserver.monitorSection = lib.mkOption {
###     apply = old: ''
###         DisplaySize ${toString (3840. / dpi * 25.4)} ${toString (2160. / dpi * 25.4)}
### #       EndSection
### #       Section "Monitor"
### #         Identifier "Monitor[1]"
### #         DisplaySize ${toString (2560. / 96. * 25.4)} ${toString (1440. / 96. * 25.4)}
### #         Option "Ignore" "true"
###     '';
###   };

#   options.services.xserver.deviceSection = lib.mkOption {
#     apply = old: ''
#         Option "Monitor-DP-2" "Monitor[0]"
#         Option "Monitor-HDMI-0" "Monitor[1]"
#     '';
#   };
}
