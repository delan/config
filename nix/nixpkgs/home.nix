{ config, pkgs, ... }: {
  home.sessionVariables = {
    # FIXME broken for like a year
    # https://www.reddit.com/r/linux/comments/72mfv8
    MOZ_USE_XINPUT2 = 1;

    # https://wiki.archlinux.org/index.php/HiDPI#Qt_5
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  home.packages = with pkgs; let
    # FIXME disabled while debugging X11 ABI problem?
    # next = import <nixos-unstable> { config = { allowUnfree = true; }; };
  in [
    #binutils-unwrapped
    #jetbrains.idea-community
    #platformio
    aria2
    atool
    bc
    cabextract
    cdrkit
    clang
    clang-tools
    dnsutils
    exiftool
    fd
    ffmpeg
    gdb
    geeqie
    gimp
    git-lfs
    gnome3.gnome-font-viewer
    gnumake
    google-chrome
    htop
    imagemagick
    inkscape
    jq
    kdenlive
    libreoffice
    linuxKernel.packages.linux_5_15.perf
    maim
    man-pages
    mc
    minicom
    mpv
    neofetch
    networkmanagerapplet
    nix-diff
    nix-index
    nmap
    obs-studio
    obsidian
    okular
    openjdk17
    opentabletdriver
    openvpn
    p7zip
    patchelf
    pavucontrol
    pcmanfm
    pup
    pv
    python3
    remmina
    ripgrep
    rnix-lsp
    rustup
    smartmontools
    soundfont-fluid
    spotify
    sqlite
    sshfs-fuse
    steam-run
    tdesktop
    termite
    texlive.combined.scheme-full
    timidity
    tmux
    units
    unzip
    vim
    virt-viewer
    vscode
    weechat
    wget
    whois
    winetricks
    wineWowPackages.full
    xclip
    xdotool
    xorg.xmodmap
    youtube-dl
    zip

    # https://nixos.wiki/wiki/Discord#Opening_Links_with_Firefox
    # https://github.com/NixOS/nixpkgs/issues/108995#issuecomment-826358042
    (discord.override { nss = nss_latest; })

    (callPackage ./osu.nix {})
    # (callPackage /home/delan/code/nixpkgs/pkgs/games/osu-lazer {})
    # (callPackage /home/delan/code/nixpkgs/pkgs/games/osu-lazer/bin.nix {})
  ];

  services = {
    picom = {
      # FIXME disabled while debugging X11 ABI problem?
      enable = false;
      vSync = true;
      backend = "xrender";
      experimentalBackends = true;
      extraOptions = ''
        xrender-sync-fence = true;
        show-all-xerrors = true;
      '';
    };

    # FIXME key bindings broken since NixOS 22.05?
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
    # emacs.enable = true;

    # needed for NIX_AUTO_RUN etc in NixOS 22.05+
    command-not-found.enable = true;

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
