{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    interactive = mkOption { type = types.bool; default = false; };
  };

  config = mkIf config.internal.interactive {
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    environment.systemPackages = with pkgs; [
      i3lock
      fxlinuxprintutil
    ];

    programs = {
      xss-lock = {
        enable = true;
        lockerCommand = "i3lock";
      };
    };

    services = {
      printing = {
        enable = true;
        startWhenNeeded = true;
        drivers = with pkgs; [ fxlinuxprint ];
      };

      xserver = {
        enable = true;
        exportConfiguration = true;
        layout = "us(mac)";
        xkbOptions = "compose:menu,caps:backspace";

        # TODO laptop
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

      # for nm-applet (to store AnyConnect secrets)
      # gnome.gnome-keyring.enable = true;
    };

    # for nm-applet (to store AnyConnect secrets)
    security.pam.services.lightdm.enableGnomeKeyring = true;
    security.pam.services.i3lock.enableGnomeKeyring = true;
    # security.wrappers = {
    #   gnome-keyring-daemon = {
    #     source = "${pkgs.gnome3.gnome-keyring}/bin/gnome-keyring-daemon";
    #     capabilities = "cap_ipc_lock+ep";
    #   };
    # };

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

    # for barrier
    networking.firewall.allowedTCPPorts = [ 24800 ];
  };
}
