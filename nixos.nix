{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal = with types; {
    hostId = mkOption { type = types.str; };
    hostName = mkOption { type = types.str; };
    domain = mkOption { type = types.str; };
    luksDevice = mkOption { type = types.str; };
    bootDevice = mkOption { type = types.str; };
    swapDevice = mkOption { type = types.nullOr types.str; };
    separateNix = mkOption { type = types.bool; };
    oldCuffsNames = mkOption { type = types.bool; };
    unstableWorkstationsCompat = mkOption { type = types.bool; };
    initialUser = mkOption { type = types.str; };

    tailscale = mkOption { type = types.bool; default = false; };
    laptop = mkOption { type = types.bool; default = false; };
    interactive = mkOption { type = types.bool; default = false; };
    i3 = mkOption { type = types.bool; default = false; };
    plasma = mkOption { type = types.bool; default = false; };
    virtualisation = {
      libvirt = mkOption { type = types.bool; default = false; };
      docker = mkOption { type = types.bool; default = false; };
      virtualbox = mkOption { type = types.bool; default = false; };
      vmware = mkOption { type = types.bool; default = false; };
    };
    igalia = mkOption { type = types.bool; default = false; };

    ids = mkOption {
      type = attrsOf (submodule {
        options = {
          id = mkOption { type = types.int; };
          force = mkOption { type = types.bool; default = false; };
          port = mkOption { type = types.int; };
        };
      });
      default = {};
    };
  };

  config = let
    cfg = config.internal;
    rootZpool = if cfg.oldCuffsNames then "cuffs" else "${cfg.hostName}";
  in mkMerge [


    (mkIf (cfg.swapDevice != null) {
      swapDevices = [ {
        device = cfg.swapDevice;
        randomEncryption = {
          enable = true;
          cipher = "aes-xts-plain64";
          source = "/dev/random";
        };
      } ];
    })


    (mkIf cfg.separateNix {
      fileSystems."/nix" =
        { device = "${rootZpool}/nix";
          fsType = "zfs";
        };
    })


    {
      sops.secrets.BUSTED_WEBHOOK.sopsFile = secrets/BUSTED_WEBHOOK.yaml;

      networking.hostId = config.internal.hostId;
      networking.hostName = config.internal.hostName;
      networking.domain = config.internal.domain;
      system.stateVersion = "18.09";

      fileSystems = {
        "/" = { device = "${rootZpool}/root"; fsType = "zfs"; };
        "/home" = { device = "${rootZpool}/home"; fsType = "zfs"; };
        "/boot" = { device = cfg.bootDevice; fsType = "vfat"; };
        "/mnt/sd" = {
          device = "/dev/disk/by-uuid/4662-B6FE"; fsType = "vfat";
          options = ["user" "noauto" "time_offset=480"];  # UTC+8
        };
        "/mnt/sd2" = {
          device = "/dev/disk/by-uuid/EE71-3FB8"; fsType = "vfat";
          options = ["user" "noauto" "time_offset=480"];  # UTC+8
        };
        "/mnt/scsi" = {
          device = "/dev/disk/by-uuid/42A6-41C6"; fsType = "vfat";
          options = ["user" "noauto"];
        };
      };

      users.users."${config.internal.initialUser}" = {
        isNormalUser = true;
        uid = 1000;
        shell = pkgs.zsh;
        extraGroups = [ "wheel" "systemd-journal" "networkmanager" ];

        # hunter2
        initialHashedPassword = "$6$4NkWaZ7Un5r.CR2C$I22bgLqKU2DxlNye4jEicYmV06BFjcwe60q.cigaTQjeviYK0Aq7MITV09koexPSBPdvsibIxYo0rYwOJ7dlg0";
      };

      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        # for nheko-0.12.1
        "olm-3.2.16"

        "jitsi-meet-1.0.8792"
        # <https://github.com/sublimehq/sublime_text/issues/5984#issuecomment-3172332375>
        "openssl-1.1.1w"
        # for darktable-5.2.1
        "ilmbase-2.5.10"
      ];
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';
      nix.settings = {
        sandbox = true;
        substituters = [
          # Lower than cache.nixos.org, to avoid wasting time hitting this cache for non-autost packages
          # <https://github.com/NixOS/nixpkgs/issues/158356#issuecomment-1030859958>
          # FIXME: disabled because it’s slow, even with the lower priority??
          # "https://autost.cachix.org?priority=41"
        ];
        trusted-public-keys = [
          "autost.cachix.org-1:zl/QINkEtBrk/TVeogtROIpQwQH6QjQWTPkbPNNsgpk="
        ];
      };

      console.keyMap = "us";
      i18n.defaultLocale = "en_AU.UTF-8";
      time.timeZone = "Australia/Perth";

      boot = {
        initrd.luks.devices = {
          "${rootZpool}" = {
            device = config.internal.luksDevice;
          };
        };

        loader = {
          systemd-boot.enable = true;
          systemd-boot.memtest86.enable = true;
          efi.canTouchEfiVariables = true;
        };

        tmp.cleanOnBoot = true;
        supportedFilesystems = [ "zfs" "xfs" ];

        kernel.sysctl = {
          # enable all magic sysrq functions
          # https://github.com/NixOS/nixpkgs/issues/83694
          # https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
          "kernel.sysrq" = 1;
        };

        extraModprobeConfig = ''
          # CVE-2026-31431 <https://copy.fail>
          install algif_aead /bin/false

          # CVE-2026-43284 and CVE-2026-43500
          # <https://github.com/V4bel/dirtyfrag>
          install esp4 /bin/false
          install esp6 /bin/false
          install rxrpc /bin/false
        '';
      };

      hardware.enableAllFirmware = true;
      hardware.keyboard.zsa.enable = true;
      hardware.logitech.wireless.enable = true;
      hardware.logitech.wireless.enableGraphical = true;

      networking = {
        networkmanager = {
          enable = true;
          connectionConfig."ipv6.ip6-privacy" = 2;
        };

        # fucking breaks everything
        dhcpcd.enable = false;
      };

      # <https://github.com/NixOS/nixpkgs/issues/375352>
      environment.etc."strongswan.conf".text = "";

      # default since 22.05, but our stateVersion is 18.09
      virtualisation.oci-containers.backend = "podman";

      services = {
        fwupd.enable = true;

        openssh = {
          enable = true;
          startWhenNeeded = true;
        };

        logind =
          if cfg.unstableWorkstationsCompat
          then {
            settings.Login.HandlePowerKey = "ignore";
          }
          else {
            extraConfig = mkIf (!cfg.unstableWorkstationsCompat) ''
              HandlePowerKey=ignore
            '';
          };

        unbound = {
          # TODO add stub zones for vpn party and enable?
          enable = lib.mkDefault false;

          # fuck DNSSEC
          enableRootTrustAnchor = false;

          settings = {
            server = {
              use-caps-for-id = true;
              qname-minimisation = true;
              # qname-minimisation-strict = true;
              # verbosity = 3;
              # do-ip6 = false;
            };
          };
        };

        openiscsi = {
          enable = true;
          name = "iqn.2015-05.cat.daz.${config.internal.hostName}:initiator";
        };
      };

      programs = {
        mosh.enable = true;
        mtr.enable = true;

        zsh = {
          enable = true;

          # TODO document
          promptInit = "";
        };

        gnupg.agent = {
          enable = true;
        };

        # for sshfs -o allow_other,default_permissions,idmap=user
        fuse.userAllowOther = true;
      };

      security.sudo.extraRules = [{
        groups = [ "wheel" ];
        commands = [
          { options = [ "NOPASSWD" ]; command = "/run/current-system/sw/bin/nixos-rebuild switch"; }
          { options = [ "NOPASSWD" ]; command = "/run/current-system/sw/bin/nixos-rebuild switch --upgrade"; }
          { options = [ "NOPASSWD" ]; command = "/run/current-system/sw/bin/zfs"; }
        ];
      }];

      environment.systemPackages = with pkgs; [
        git # needed for nixos-rebuild with flakes
        ripgrep # needed for /root/sync.sh
        nix-output-monitor # nixos-rebuild --log-format internal-json -v switch 2>&1 | nom --json
        sops # needed for editing secrets in this repo
        nix-diff
        nix-doc
        nix-index

        atool
        bore
        dnsutils
        fd
        htop
        jmtpfs
        man-pages
        neofetch
        p7zip
        patchelf
        pv
        rink
        ripgrep
        sshfs-fuse
        steam-run
        tmux
        unzip
        vim
        whois
        zip

        (writeScriptBin "darktable-exported.sh" (readFile bin/darktable-exported.sh))
        (writeScriptBin "markdown-photos.sh" (readFile bin/markdown-photos.sh))
        (writeScriptBin "midi.sh" (readFile bin/midi.sh))
        (writeScriptBin "nef2jpg.sh" (readFile bin/nef2jpg.sh))
        (writeScriptBin "photo-details.sh" (readFile bin/photo-details.sh))
        (writeScriptBin "rsync.sh" (readFile bin/rsync.sh))
        (writeScriptBin "screenshot.sh" (readFile bin/screenshot.sh))
        (writeScriptBin "slock" (readFile bin/slock))
        (writeScriptBin "smart.sh" (readFile bin/smart.sh))
          smartmontools
        (writeScriptBin "ssg.sh" (readFile bin/ssg.sh))
        (writeScriptBin "sync.sh" (readFile bin/sync.sh))
        (writeScriptBin "wine.sh" (readFile bin/wine.sh))
        (writeScriptBin "zfs-iostat-totals" (readFile bin/zfs-iostat-totals))
        (writeScriptBin "zfs-sync-snapshots" (readFile bin/zfs-sync-snapshots))
        (writeScriptBin "zfs-thin-snapshots" (readFile bin/zfs-thin-snapshots))

        (writeScriptBin "sync-colo.sh" (readFile bin/sync-colo.sh))
        (writeScriptBin "sync-jupiter.sh" (readFile bin/sync-jupiter.sh))
        (writeScriptBin "sync-tol.sh" (readFile bin/sync-tol.sh))
        (writeScriptBin "sync-venus.sh" (readFile bin/sync-venus.sh))

        # <https://git.isincredibly.gay/srxl/gemstone-labs.nix/src/commit/21e905f71929a54b5f5e25ce9dbe2e5cf0bc4fc9/deploy>
        fish
        (writeScriptBin "deploy" (readFile bin/deploy))
      ];
    }


    {
      users = foldl' lib.recursiveUpdate {} (
        map
        (name: let
          mkPriority = if config.internal.ids."${name}".force
            then lib.mkForce
            else lib.trivial.id;
          id = config.internal.ids."${name}".id;
        in {
          users."${name}" = {
            uid = mkPriority id;
            group = name;
            isSystemUser = true;
          };
          groups."${name}" = {
            gid = mkPriority id;
          };
        })
        (attrNames config.internal.ids)
      );
    }


    (mkIf cfg.tailscale {
      services.tailscale = {
        enable = true;
        openFirewall = true;
      };

      # Make tailscaled.service not come up until tailscale actually connects
      # Fix for <https://github.com/tailscale/tailscale/issues/11504>
      systemd.services.tailscaled.postStart = "until ${pkgs.tailscale}/bin/tailscale status; do sleep 1; done";
      systemd.services.tailscaled.serviceConfig.TimeoutStartSec = "10";
    })


    (mkIf cfg.laptop {
      services = {
        # conflicts with plasma5 and also is discouraged on modern amd?
        tlp.enable = false;

        # https://bugzilla.kernel.org/show_bug.cgi?id=198931
        # https://askubuntu.com/questions/1044127
        tlp.settings = { USB_BLACKLIST = "17ef:3082"; };

        logind =
          if cfg.unstableWorkstationsCompat
          then {
            settings.Login.HandleLidSwitchExternalPower = "ignore";
          }
          else {
            extraConfig = ''
              HandleLidSwitchExternalPower=ignore
            '';
          };

        # Energy Performance Preference control for modern cpus
        # <https://wiki.archlinux.org/title/CPU_frequency_scaling#Autonomous_frequency_scaling>
        cpupower-gui.enable = true;
        auto-epp = {
          enable = true;
          settings.Settings = {
            # epp_state_for_AC = "balance_performance";  # same as firmware default
            epp_state_for_AC = "power";  # firmware default is balance_performance
            epp_state_for_BAT = "power";  # firmware default is balance_power
          };
        };
      };

      programs.light.enable = true;
    })


    (mkIf (!cfg.laptop) {
      powerManagement.cpuFreqGovernor = "performance";
    })


    (mkIf config.internal.interactive {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      hardware = {
        pulseaudio.enable = false;

        # 32-bit game support
        graphics.enable32Bit = true;

        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };
      services.blueman.enable = true;

      environment.systemPackages = with pkgs; [
        fxlinuxprintutil
      ];

      services = {
        printing = {
          enable = true;
          startWhenNeeded = true;
          drivers = [ pkgs.fxlinuxprint ];
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

      # for services.desktopManager.plasma6 et al (/dev/dri)
      users.users."${config.internal.initialUser}".extraGroups = [ "video" ];
    })


    (mkIf config.internal.i3 {
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

      services.xserver = {
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

      # FIXME: this often spams systemd logs with failures
      services.picom.enable = true;

      programs.xss-lock = {
        enable = true;
        lockerCommand = "i3lock";
      };
    })


    (mkIf config.internal.plasma {
      # <https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/doc/manual/configuration/profiles/graphical.section.md?plain=1#L6-L9>
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
      services.libinput.enable = true;
    })


    (mkIf cfg.virtualisation.libvirt (mkMerge [
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu.runAsRoot = false;
          onShutdown = "shutdown";
          allowedBridges = [ "virbr0" "virbr1" "bridge13" "solserv" ];
        };

        users.users."${config.internal.initialUser}".extraGroups = [ "libvirtd" ];

        networking.firewall.allowedTCPPortRanges = [
          # libvirt migration
          { from = 49152; to = 49215; }
        ];
      }

      (mkIf cfg.interactive {
        environment.systemPackages = with pkgs; [ virt-manager dconf ];
        programs.dconf.enable = true;
      })
    ]))


    (mkIf cfg.virtualisation.docker {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = false;

        # NixOS/nixpkgs#182916
        liveRestore = false;

        daemon = {
          settings = {
            storage-driver = "overlay2";

            # docker’s ip6tables feature breaks ipv6 connectivity to machines and libvirt guests
            # on unrelated bridges, because it sets the default policy of FORWARD to DROP.
            # avoid that mess by leaving all of docker’s ipv6 features disabled.
            # <https://github.com/moby/moby/issues/48365>
            # <https://docs.docker.com/engine/release-notes/27/#ipv6>
            # <https://docs.docker.com/engine/release-notes/28/#port-publishing-in-bridge-networks>
            ipv6 = false;
            ip6tables = false;
          };
        };
      };

      users.users."${config.internal.initialUser}".extraGroups = [ "docker" ];
    })


    (mkIf cfg.virtualisation.virtualbox {
      virtualisation.virtualbox.host = {
        enable = true;
        enableExtensionPack = true;
      };

      users.users."${config.internal.initialUser}".extraGroups = [ "vboxusers" ];
    })


    (mkIf cfg.virtualisation.vmware {
      virtualisation.vmware.host.enable = true;
    })


    (mkIf cfg.igalia {
      services.unbound.settings.stub-zone = [
        { name = "local.igalia.com."; stub-addr = "192.168.10.14"; }
        { name = "10.168.192.in-addr.arpa."; stub-addr = "192.168.10.14"; }
      ];

      # Gobby + Linphone
      # FIXME broken under wayland
      services.flatpak.enable = true;
      # 2026-01-02 reduce battery usage (see lab notebook)
      # xdg.portal.enable = true;
      # xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      # xdg.portal.config.common.default = "*";  # use first portal impl in lexicographic order

      # https://gitlab.igalia.com/support/people/selection-processes/-/blob/e0a5aa58626d22babcfd1f8e117864c49f658e4e/tools/import_issue.py
      services.gnome.gnome-keyring.enable = true;

      networking.hosts = {
        "127.0.0.1" = [
          "www1.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "op88.web-platform.test"
          "op36.not-web-platform.test"
          "op53.not-web-platform.test"
          "op50.not-web-platform.test"
          "xn--lve-6lad.www.web-platform.test"
          "op98.web-platform.test"
          "op24.not-web-platform.test"
          "op31.not-web-platform.test"
          "op95.not-web-platform.test"
          "op85.web-platform.test"
          "op83.not-web-platform.test"
          "www2.not-web-platform.test"
          "xn--lve-6lad.www.not-web-platform.test"
          "op73.not-web-platform.test"
          "op8.web-platform.test"
          "www2.www2.not-web-platform.test"
          "op89.web-platform.test"
          "op66.web-platform.test"
          "xn--lve-6lad.web-platform.test"
          "op19.not-web-platform.test"
          "www1.www2.web-platform.test"
          "op72.web-platform.test"
          "op24.web-platform.test"
          "op21.not-web-platform.test"
          "xn--lve-6lad.not-web-platform.test"
          "op41.web-platform.test"
          "op79.web-platform.test"
          "op81.not-web-platform.test"
          "op70.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.xn--lve-6lad.not-web-platform.test"
          "op78.not-web-platform.test"
          "op6.not-web-platform.test"
          "www1.www.not-web-platform.test"
          "op40.not-web-platform.test"
          "op25.not-web-platform.test"
          "op3.not-web-platform.test"
          "op65.not-web-platform.test"
          "op91.web-platform.test"
          "www.www2.web-platform.test"
          "op80.not-web-platform.test"
          "op59.web-platform.test"
          "op52.not-web-platform.test"
          "xn--lve-6lad.xn--lve-6lad.web-platform.test"
          "op68.not-web-platform.test"
          "op45.not-web-platform.test"
          "op71.not-web-platform.test"
          "op72.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www2.web-platform.test"
          "op39.web-platform.test"
          "op90.not-web-platform.test"
          "op60.web-platform.test"
          "op58.web-platform.test"
          "op28.web-platform.test"
          "www1.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.xn--lve-6lad.web-platform.test"
          "op14.web-platform.test"
          "op89.not-web-platform.test"
          "op69.web-platform.test"
          "op49.not-web-platform.test"
          "op40.web-platform.test"
          "op2.not-web-platform.test"
          "op5.not-web-platform.test"
          "www.www2.not-web-platform.test"
          "op77.not-web-platform.test"
          "www.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "op7.web-platform.test"
          "op74.web-platform.test"
          "op79.not-web-platform.test"
          "op82.not-web-platform.test"
          "www.www1.web-platform.test"
          "op12.not-web-platform.test"
          "op39.not-web-platform.test"
          "op31.web-platform.test"
          "www.not-web-platform.test"
          "www.www.not-web-platform.test"
          "op44.not-web-platform.test"
          "www1.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www1.web-platform.test"
          "op58.not-web-platform.test"
          "op14.not-web-platform.test"
          "op30.not-web-platform.test"
          "op62.not-web-platform.test"
          "op61.not-web-platform.test"
          "op92.not-web-platform.test"
          "www2.xn--lve-6lad.web-platform.test"
          "op29.not-web-platform.test"
          "op18.web-platform.test"
          "op73.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "op77.web-platform.test"
          "op12.web-platform.test"
          "op54.web-platform.test"
          "op63.web-platform.test"
          "op71.web-platform.test"
          "www2.www1.not-web-platform.test"
          "op95.web-platform.test"
          "op16.web-platform.test"
          "op36.web-platform.test"
          "op27.web-platform.test"
          "www.www.web-platform.test"
          "op98.not-web-platform.test"
          "op64.not-web-platform.test"
          "op29.web-platform.test"
          "op9.web-platform.test"
          "op26.not-web-platform.test"
          "op22.not-web-platform.test"
          "op94.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www2.not-web-platform.test"
          "op44.web-platform.test"
          "op94.not-web-platform.test"
          "op33.web-platform.test"
          "op38.not-web-platform.test"
          "op33.not-web-platform.test"
          "op84.web-platform.test"
          "www1.www1.not-web-platform.test"
          "op23.not-web-platform.test"
          "op57.not-web-platform.test"
          "op54.not-web-platform.test"
          "op85.not-web-platform.test"
          "www2.www2.web-platform.test"
          "op46.not-web-platform.test"
          "op97.not-web-platform.test"
          "op32.web-platform.test"
          "op61.web-platform.test"
          "op70.web-platform.test"
          "www2.web-platform.test"
          "op32.not-web-platform.test"
          "op60.not-web-platform.test"
          "op4.web-platform.test"
          "op43.web-platform.test"
          "op7.not-web-platform.test"
          "op78.web-platform.test"
          "op26.web-platform.test"
          "xn--lve-6lad.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "op96.not-web-platform.test"
          "op51.not-web-platform.test"
          "op41.not-web-platform.test"
          "op76.web-platform.test"
          "op52.web-platform.test"
          "op99.web-platform.test"
          "op35.not-web-platform.test"
          "op99.not-web-platform.test"
          "op86.web-platform.test"
          "not-web-platform.test"
          "op42.not-web-platform.test"
          "op46.web-platform.test"
          "op67.not-web-platform.test"
          "op17.web-platform.test"
          "op90.web-platform.test"
          "op93.web-platform.test"
          "op37.not-web-platform.test"
          "op48.not-web-platform.test"
          "op10.web-platform.test"
          "op55.not-web-platform.test"
          "op4.not-web-platform.test"
          "www1.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "op55.web-platform.test"
          "xn--lve-6lad.www2.web-platform.test"
          "op47.web-platform.test"
          "op51.web-platform.test"
          "op45.web-platform.test"
          "op80.web-platform.test"
          "op68.web-platform.test"
          "op49.web-platform.test"
          "op57.web-platform.test"
          "www2.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "www.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "op56.not-web-platform.test"
          "web-platform.test"
          "op84.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "xn--lve-6lad.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "op34.not-web-platform.test"
          "op6.web-platform.test"
          "op35.web-platform.test"
          "op67.web-platform.test"
          "op69.not-web-platform.test"
          "op11.not-web-platform.test"
          "op93.not-web-platform.test"
          "www1.www.web-platform.test"
          "op86.not-web-platform.test"
          "op8.not-web-platform.test"
          "www2.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "op92.web-platform.test"
          "xn--lve-6lad.www1.not-web-platform.test"
          "op15.web-platform.test"
          "op13.not-web-platform.test"
          "op13.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www.web-platform.test"
          "op75.web-platform.test"
          "op20.not-web-platform.test"
          "op76.not-web-platform.test"
          "op64.web-platform.test"
          "op97.web-platform.test"
          "op37.web-platform.test"
          "op56.web-platform.test"
          "op62.web-platform.test"
          "op82.web-platform.test"
          "op25.web-platform.test"
          "op11.web-platform.test"
          "www.xn--lve-6lad.not-web-platform.test"
          "www2.www1.web-platform.test"
          "op27.not-web-platform.test"
          "op50.web-platform.test"
          "op17.not-web-platform.test"
          "op38.web-platform.test"
          "www2.www.not-web-platform.test"
          "xn--lve-6lad.www1.web-platform.test"
          "op75.not-web-platform.test"
          "op83.web-platform.test"
          "op81.web-platform.test"
          "op15.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www.not-web-platform.test"
          "op20.web-platform.test"
          "op3.web-platform.test"
          "www1.www2.not-web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
          "op2.web-platform.test"
          "op21.web-platform.test"
          "op23.web-platform.test"
          "op42.web-platform.test"
          "op47.not-web-platform.test"
          "www1.www1.web-platform.test"
          "op18.not-web-platform.test"
          "op22.web-platform.test"
          "xn--lve-6lad.xn--lve-6lad.not-web-platform.test"
          "op63.not-web-platform.test"
          "op28.not-web-platform.test"
          "op65.web-platform.test"
          "www.www1.not-web-platform.test"
          "www1.xn--lve-6lad.web-platform.test"
          "op43.not-web-platform.test"
          "op66.not-web-platform.test"
          "www2.www.web-platform.test"
          "op96.web-platform.test"
          "op91.not-web-platform.test"
          "www.xn--lve-6lad.web-platform.test"
          "op1.web-platform.test"
          "op74.not-web-platform.test"
          "op87.web-platform.test"
          "op59.not-web-platform.test"
          "op19.web-platform.test"
          "xn--n8j6ds53lwwkrqhv28a.www1.not-web-platform.test"
          "op9.not-web-platform.test"
          "op88.not-web-platform.test"
          "op53.web-platform.test"
          "www2.xn--lve-6lad.not-web-platform.test"
          "op87.not-web-platform.test"
          "op30.web-platform.test"
          "op10.not-web-platform.test"
          "op48.web-platform.test"
          "op16.not-web-platform.test"
          "op34.web-platform.test"
          "op1.not-web-platform.test"
          "www.web-platform.test"
          "op5.web-platform.test"
          "www1.xn--lve-6lad.not-web-platform.test"
          "xn--lve-6lad.www2.not-web-platform.test"
        ];
      };
    })


  ];
}
