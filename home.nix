{ config, pkgs, ... }: {
  home.stateVersion = "22.11";

  home.sessionVariables = {
    # https://www.reddit.com/r/linux/comments/72mfv8
    MOZ_USE_XINPUT2 = 1;

    # https://wiki.archlinux.org/index.php/HiDPI#Qt_5
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  home.packages = with pkgs; let
  in [
    #binutils-unwrapped
    #jetbrains.idea-community
    #platformio
    alacritty
    aria2
    atool
    bc
    bore
    cabextract
    cdrkit
    clang
    clang-tools
    darktable
    dnsutils
    exiftool
    fd
    ffmpeg
    gdb
    geeqie
    gh
    gimp
    git-lfs
    gnome-font-viewer
    gnumake
    google-chrome
    htop
    imagemagick
    inkscape
    jmtpfs
    jq
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.kdenlive
    kdePackages.okular
    kicad
    libnotify
    libreoffice
    lxappearance
    maim
    man-pages
    mc
    mercurialFull
    minicom
    mpv
    neofetch
    networkmanager-openvpn
    networkmanagerapplet
    nheko
    nix-diff
    nix-index
    nmap
    nodejs
    obs-studio
    obsidian
    openjdk17
    opentabletdriver
    openvpn
    osu-lazer-bin
    p7zip
    patchelf
    pavucontrol
    pcmanfm
    prismlauncher
    pulseaudio  # for pactl in i3
    pup
    pv
    python3
    remmina
    rink
    ripgrep
    rustup
    smartmontools
    soundfont-fluid
    spotify
    sqlite
    sshfs-fuse
    steam
    steam-run
    tdesktop
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
    yt-dlp
    zip

    # https://nixos.wiki/wiki/Discord#Opening_Links_with_Firefox
    # https://github.com/NixOS/nixpkgs/issues/108995#issuecomment-826358042
    (discord.override { nss = nss_latest; })
  ];

  services = {
    picom = {
      enable = true;
      vSync = true;
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

          # shortcuts
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

    blueman-applet.enable = true;
  };

  programs = {
    home-manager.enable = true;
    firefox.enable = true;
    thunderbird.enable = true;
    thunderbird.profiles = {};

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
      enable = false;
      userName = "Delan Azabani";
      userEmail = "delan@azabani.com";
      extraConfig = ''
        tweakdefaults = true
        [extensions]
        eol =
        strip =
        [diff]
        git = true
        showfunc = true
        [extensions]
        absorb =
        histedit =
        rebase =
        evolve = /home/delan/.mozbuild/evolve/hgext3rd/evolve
        shelve =
        firefoxtree = /home/delan/.mozbuild/version-control-tools/hgext/firefoxtree
        clang-format = /home/delan/.mozbuild/version-control-tools/hgext/clang-format
        js-format = /home/delan/.mozbuild/version-control-tools/hgext/js-format
        show =
        push-to-try = /home/delan/.mozbuild/version-control-tools/hgext/push-to-try
        [rebase]
        experimental.inmemory = yes
        [alias]
        wip = log --graph --rev=wip --template=wip
        smart-annotate = annotate -w --skip ignored_changesets
        [revsetalias]
        wip = (parents(not public()) or not public() or . or (head() and branch(default))) and (not obsolete() or orphan()^) and not closed() and not (fxheads() - date(-90))
        ignored_changesets = desc("ignore-this-changeset") or extdata(get_ignored_changesets)
        [templates]
        wip = '{label("wip.branch", if(branches,"{branches} "))}{label(ifeq(graphnode,"x","wip.obsolete","wip.{phase}"),"{rev}:{node|short}")}{label("wip.user", " {author|user}")}{label("wip.tags", if(tags," {tags}"))}{label("wip.tags", if(fxheads," {fxheads}"))}{if(bookmarks," ")}{label("wip.bookmarks", if(bookmarks,bookmarks))}{label(ifcontains(rev, revset("parents()"), "wip.here"), " {desc|firstline}")}'
        [color]
        wip.bookmarks = yellow underline
        wip.branch = yellow
        wip.draft = green
        wip.here = red
        wip.obsolete = none
        wip.public = blue
        wip.tags = yellow
        wip.user = magenta
        [experimental]
        graphshorten = true
        [extdata]
        get_ignored_changesets = shell:cat `hg root`/.hg-annotate-ignore-revs 2> /dev/null || true
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
      terminal = "alacritty";
      theme = "Monokai";
    };

    feh = {
      enable = true;
    };
  };

  gtk.enable = true;
  gtk.iconTheme = {
    package = pkgs.kdePackages.breeze-icons;
    name = "breeze";
  };
  qt.enable = true;
  qt.style = {
    package = pkgs.kdePackages.breeze;
    name = "breeze";
  };

  # see environment.systemPackages in lib/interactive.nix
  home.file.".xinitrc".text = ''
    xinitrc
  '';
}
