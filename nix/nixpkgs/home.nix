{ config, pkgs, ... }: {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  home.sessionVariables = {
    # https://www.reddit.com/r/linux/comments/72mfv8
    MOZ_USE_XINPUT2 = 1;

    # https://wiki.archlinux.org/index.php/HiDPI#Qt_5
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

home.packages = let
	next = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
	with pkgs; let
    # nodejs = ((callPackage ~/code/GitHub/delan/nixpkgs/pkgs/development/web/nodejs/v12.nix {}).override({
      # libuv = callPackage ~/code/GitHub/delan/nixpkgs/pkgs/development/libraries/libuv {
        # inherit (darwin.apple_sdk.frameworks) ApplicationServices CoreServices;
      # };
    # }));
  in [
    next._1password next._1password-gui next.google-chrome-dev
    networkmanagerapplet termite virtmanager geeqie smartmontools pavucontrol
    tmux htop vim fzf fd pv bat neofetch (ripgrep.override { withPCRE2 = true; })

    atool unzip zip cabextract jq aria nmap dnsutils liboping
    weechat next.discord slack tdesktop okular remmina
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
    next.vscode

    nix-index manpages git-lfs clang clang-tools ccls patchelf
    gnumake # binutils
    texlive.combined.scheme-full
    bundler # clang
    # node yarn # nodejs-11_x
#     nodejs (callPackage ~/code/GitHub/delan/nixpkgs/pkgs/development/tools/yarn {
#       inherit nodejs;
#     })
    # .override({
    #   buildNodejs = callPackage ~/code/GitHub/delan/nixpkgs/pkgs/development/web/nodejs/nodejs.nix {
    #     inherit openssl icu;
    #     python = python2;
    #     util-linux = utillinux;
    #   };
    # })
    pkgs.nodejs
    openssl
    nasm qemu bochs
    ispell docker-compose # php php73Packages.composer
    wineWowPackages.full winetricks

    # provides rls
    # latest.rustChannels.stable.rust
    rustup

    # migrate to firefox.package once it works
    # firefox-devedition-bin

    maim xdotool # for rofi-ss
    gnome3.seahorse # for gnome3.gnome-keyring

    units

    nix-diff

    bc xclip zoom-us filezilla google-chrome imagemagick cdrkit whois openvpn
    linuxPackages.perf next.jdk17 maven # neovim-nightly jdk11 jdk8
    steam inkscape libreoffice
    uefitool
    run-scaled
    timidity soundfont-fluid
    drawio
    wget
    python3

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
    picom = {
      enable = true;
      vSync = true;
      backend = "xrender";
      experimentalBackends = true;
      extraOptions = ''
        xrender-sync-fence = true;
        show-all-xerrors = true;
      '';
    };
    dunst = {
      enable = true;
      settings = {
        global = {
          font = "Inconsolata 13";
          markup = "full";
          format = "<b>%s</b>\n%b";
          monitor = 0;
          follow = "mouse";
          geometry = "1000x50-10+10";
          indicate_hidden = true;
          sort = true;
          alignment = "left";
          shrink = true;
          separator_height = 4;
          padding = 16;
          horizontal_padding = 16;
          separator_color = "auto";
          idle_threshold = 120;
          show_age_threshold = 60;
          word_wrap = true;
          ignore_newline = false;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = false;
          history_length = 20;
          title = "Dunst";
          class = "Dunst";
          browser = "/run/current-system/sw/bin/xdg-open";
          startup_notification = false;
          always_run_script = true;
          icon_position = "left";
          frame_color = "#000000";
          frame_width = 1;
        };
        shortcuts = {
          close = "ctrl+space";
          close_all = "ctrl+shift+space";
          context = "ctrl+shift+p";
          history = "ctrl+grave";
        };
        urgency_low = {
          background = "#121c21";
          foreground = "#aaafb2";
          timeout = 4;
        };
        urgency_normal = {
          background = "#ffffff";
          foreground = "#000000";
          timeout = 6;
        };
        urgency_critical = {
          background = "#121c21";
          foreground = "#aaafb2";
          timeout = 0;
        };
      };
    };
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
      extraConfig = {
	      modi = "run,ssh,combi";
	      ssh-client = "mosh";
	      ssh-command = ''{terminal} -e "{ssh-client} {host}"'';
	      combi-modi = "drun,ssh,run";
      };
      terminal = "termite";
      theme = "Monokai";
    };

    feh = {
      enable = true;
    };
  };
}
