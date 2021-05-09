{ config, pkgs, ... }: {
  home.sessionVariables = {
    # https://www.reddit.com/r/linux/comments/72mfv8
    MOZ_USE_XINPUT2 = 1;
  };

  home.packages = with pkgs; [
    dunst networkmanagerapplet termite virtmanager geeqie smartmontools pavucontrol
    tmux htop vim fzf fd pv bat neofetch (ripgrep.override { withPCRE2 = true; })

    atool unzip zip cabextract jq aria nmap dnsutils liboping
    weechat discord slack tdesktop okular remmina
    keepass mpv gimp gnome3.gnome-font-viewer
    kdenlive ffmpeg
    aria2 youtubeDL
    sshfs-fuse
    barrier
    minecraft
    audacity
    mediainfo
    obs-studio
    spotify
    # skype

    nix-index manpages git-lfs clang clang-tools ccls patchelf
    binutils gnumake
    texlive.combined.scheme-full
    bundler # clang
    nodejs # nodejs-11_x
    openssl
    nasm qemu bochs
    ispell docker-compose php php73Packages.composer
    wine winetricks

    # provides rls
    # latest.rustChannels.stable.rust
    rustup

    # migrate to firefox.package once it works
    # firefox-devedition-bin

    maim xdotool # for rofi-ss
    gnome3.seahorse # for gnome3.gnome-keyring

    units

    nix-diff

    # (pkgs.haskellPackages.callCabal2nix "polishnt" ~/code/GitHub/ar1a/polishnt {})
    # (callPackage ~/nix/nmcli-rofi {})
    # (callPackage ~/nix/adc902fc0fa11bbe {})

    # (libsForQt5.callPackage ~/nixos-19.09/pkgs/games/multimc {})
    # (multimc.override {
    #   jdk = callPackage ~/nixos-19.03/pkgs/development/compilers/openjdk/8.nix {
    #     bootjdk = callPackage ~/nixos-19.03/pkgs/development/compilers/openjdk/bootstrap.nix {
    #       version = "8";
    #     };
    #     inherit (gnome2) GConf gnome_vfs;
    #   };
    # })

    vscode
  ];

  services = {
    picom.enable = true;
  };

  programs = {
    home-manager.enable = true;
    firefox.enable = true;
    emacs.enable = true;

    git = {
      enable = true;
      userName = "Delan Azabani";
      userEmail = "delan@azabani.com";
      lfs.enable = true;
      extraConfig = {
        github = {
          user = "delan";
        };
      };
    };

    mercurial = {
      enable = true;
      userName = "Delan Azabani";
      userEmail = "delan@azabani.com";
      extraConfig = ''
        tweakdefaults = True

        [extensions]
        eol =
        strip =
        rebase =
        shelve =
        histedit =
      '';
    };

    rofi = {
      enable = true;
      extraConfig = ''
        rofi.modi: window,run,ssh,combi
        rofi.ssh-client: mosh
        rofi.ssh-command: {terminal} -e "{ssh-client} {host}"
        rofi.combi-modi: window,drun,ssh,run
      '';
      terminal = "termite";
      theme = "Monokai";
    };

    feh = {
      enable = true;
    };
  };
}
