{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    interactive = mkOption { type = types.bool; default = false; };
  };

  config = mkIf config.internal.interactive {
    sound.enable = true;
    hardware = {
      pulseaudio.enable = true;

      # 32-bit game support
      opengl.driSupport32Bit = true;
      pulseaudio.support32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      i3lock

      # FIXME uncomment in NixOS 22.11? https://github.com/NixOS/nixpkgs/pull/215160
      # fxlinuxprintutil
    ];

    programs = {
      xss-lock = {
        # FIXME disabled while debugging X11 ABI problem?
        enable = false;
        lockerCommand = "i3lock";
      };
    };

    services = {
      printing = {
        enable = true;
        startWhenNeeded = true;

        # FIXME uncomment in NixOS 22.11? https://github.com/NixOS/nixpkgs/pull/215160
        # drivers = with pkgs; [ fxlinuxprint ];
      };

      xserver = {
        enable = true;
        exportConfiguration = true;
        layout = "us(mac)";
        xkbOptions = "compose:menu,caps:backspace";

        libinput = {
          enable = true;
          touchpad.tapping = false;
          touchpad.disableWhileTyping = true;
          touchpad.naturalScrolling = true;
          # touchpad.accelProfile = "flat";
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
    };

    fonts = {
      fontconfig.defaultFonts = {
        monospace = [ "Inconsolata" ];
        sansSerif = [ "Helvetica Neue LT Std" ];
      };

      fonts = with pkgs; [
        inconsolata
        helvetica-neue-lt-std
        twemoji-color-font
        noto-fonts noto-fonts-cjk
        corefonts
      ];
    };
  };
}
