{ config, pkgs, ... }: {
  home.sessionVariables = {
    # FIXME broken for like a year
    # https://www.reddit.com/r/linux/comments/72mfv8
    MOZ_USE_XINPUT2 = 1;

    # https://wiki.archlinux.org/index.php/HiDPI#Qt_5
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  home.packages = with pkgs; let
    next = import <nixos-unstable> { config = { allowUnfree = true; }; };
  in [
    next.google-chrome-dev
    networkmanagerapplet termite geeqie smartmontools pavucontrol
    tmux htop vim fd pv neofetch ripgrep

    atool unzip zip cabextract jq nmap dnsutils
    weechat next.discord tdesktop okular remmina
    mpv gimp gnome3.gnome-font-viewer
    ffmpeg
    aria2 youtubeDL
    sshfs-fuse
    obs-studio
    spotify
    next.vscode

    nix-index manpages git-lfs clang clang-tools patchelf
    gnumake
    rustup

    maim
    units

    nix-diff

    bc xclip google-chrome imagemagick cdrkit whois openvpn
    libreoffice
    timidity soundfont-fluid
    wget
    python3
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
