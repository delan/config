{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = {
    interactive = mkOption { type = types.bool; default = false; };
  };

  config = mkIf config.internal.interactive {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    hardware = {
      pulseaudio.enable = false;

      # 32-bit game support
      graphics.enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      i3lock

      # script that ~/.xinitrc (home.nix) runs to start i3. by registering it
      # as a nixos window manager and running it with the nixos session wrapper,
      # we get a bunch of helpful features for free, like loading ~/.profile and
      # ~/.Xresources, piping output to syslog, and setting up dbus correctly.
      # see <nixpkgs>/nixos/modules/services/x11/display-managers/default.nix,
      # `let` `xsessionWrapper` and `xsession`.
      (writeScriptBin "xinitrc" ''
        #!/bin/sh
        set -eu
        session_name=none+i3-unset-shell
        session_exec=$('${pkgs.ripgrep}/bin/rg' -o --pcre2 '(?<=^Exec=).*' '${config.services.xserver.displayManager.sessionData.desktops}'/share/xsessions/"$session_name.desktop")
        exec '${config.services.xserver.displayManager.sessionData.wrapper}' "$session_exec"
      '')
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
        displayManager.startx.enable = true;  # don’t install lightdm

        # FIXME: alacritty opens with bash instead of zsh unless we register a
        # window manager that unsets $SHELL, which for some reason is unset by
        # lightdm but set to bash by startx
        displayManager.session = [{
          manage = "window";
          name = "i3-unset-shell";
          start = ''
            env -u SHELL -- ${pkgs.i3}/bin/i3 &
            waitPID=$!
          '';
        }];
      };

      libinput = {
        enable = true;
        touchpad.tapping = false;
        touchpad.disableWhileTyping = false;
        touchpad.naturalScrolling = true;
        # touchpad.accelProfile = "flat";
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
