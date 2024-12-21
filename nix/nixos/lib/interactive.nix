{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    interactive = mkOption { type = types.bool; default = false; };
  };

  config = mkIf config.internal.interactive {
    hardware = {
      pulseaudio.enable = mkDefault true;

      # 32-bit game support
      graphics.enable32Bit = true;
      pulseaudio.support32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      i3lock
    ];

    programs = {
      xss-lock = {
        enable = true;
        lockerCommand = "i3lock";
      };
    };

    services = {
      picom.enable = true;

      printing = {
        enable = true;
        startWhenNeeded = true;
      };

      xserver = {
        enable = true;
        exportConfiguration = true;
        xkb = {
          layout = "us(mac)";
          options = "compose:menu,caps:backspace";
        };

        # for mouse only
        config = ''
          Section "InputClass"
            Identifier "mouse accel"
            Driver "libinput"
            MatchIsPointer "on"
            Option "AccelProfile" "flat"
            Option "AccelSpeed" "0"
            Option "NaturalScrolling" "off"
          EndSection
        '';

        windowManager.i3.enable = true;
      };

      libinput = {
        enable = true;
        touchpad.tapping = false;
        touchpad.disableWhileTyping = false;
        touchpad.naturalScrolling = true;
        # touchpad.accelProfile = "flat";
      };

      xrdp = {
        enable = false;
        openFirewall = false;

        # After changing this:
        # $ sudo systemctl restart xrdp-sesman
        defaultWindowManager = let
          # Kill dunst, so we get notifications
          pkillDunstWrapper = pkgs.writeScript "pkillDunstWrapper" ''
            #!/bin/sh
            pkill dunst
            exec "$@"
          '';
        in let
          session = pkgs.writeScript "session" ''
            #!/bin/sh
            set -eu
            session_name=none+i3
            rg='${pkgs.ripgrep}/bin/rg'
            sessions_directory=$(< /etc/lightdm/lightdm.conf "$rg" -o --pcre2 '(?<=^sessions-directory = ).*')
            session_wrapper=$(< /etc/lightdm/lightdm.conf "$rg" -o --pcre2 '(?<=^session-wrapper = ).*')
            IFS=:
            for dir in $sessions_directory; do
                set -- -o --pcre2 '(?<=^Exec=).*' "$dir/$session_name.desktop"
                if "$rg" -q "$@"; then
                    session_exec=$("$rg" "$@")
                    break
                fi
            done
            exec "$session_wrapper" '${pkillDunstWrapper}' "$session_exec"
          '';
        in "${session}";
      };
    };

    fonts = {
      fontconfig.defaultFonts = {
        monospace = [ "Inconsolata" ];
        sansSerif = [ "Helvetica Neue LT Std" ];
      };

      packages = with pkgs; [
        inconsolata
        # FIXME hollow fonts # helvetica-neue-lt-std
        # twemoji-color-font
        noto-fonts noto-fonts-cjk-sans
        corefonts
        nanum  # for servo
        takao  # for servo
        wqy_microhei  # for servo
      ];
    };
  };
}
