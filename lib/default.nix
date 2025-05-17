{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ./interactive.nix
    ./laptop.nix
    ./igalia.nix
    ./virtualisation.nix
    ./services
    ./programs
  ];

  options.internal = with types; {
    hostId = mkOption { type = types.str; };
    hostName = mkOption { type = types.str; };
    domain = mkOption { type = types.str; };
    luksDevice = mkOption { type = types.str; };
    bootDevice = mkOption { type = types.str; };
    swapDevice = mkOption { type = types.nullOr types.str; };
    separateNix = mkOption { type = types.bool; };
    initialUser = mkOption { type = types.str; };
    tailscale = mkOption { type = types.bool; default = false; };
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
        { device = "cuffs/nix";
          fsType = "zfs";
        };
    })
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
    {
      sops.secrets.BUSTED_WEBHOOK.sopsFile = ../secrets/BUSTED_WEBHOOK.yaml;

      networking.hostId = config.internal.hostId;
      networking.hostName = config.internal.hostName;
      networking.domain = config.internal.domain;
      system.stateVersion = "18.09";

      fileSystems = {
        "/" = { device = "cuffs/root"; fsType = "zfs"; };
        "/home" = { device = "cuffs/home"; fsType = "zfs"; };
        "/boot" = { device = cfg.bootDevice; fsType = "vfat"; };
        "/mnt/sd" = {
          device = "/dev/disk/by-uuid/4662-B6FE"; fsType = "vfat";
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
      nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16" "jitsi-meet-1.0.8043"];
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';
      nix.settings = {
        sandbox = true;
        substituters = [
          # Lower than cache.nixos.org, to avoid wasting time hitting this cache for non-autost packages
          # <https://github.com/NixOS/nixpkgs/issues/158356#issuecomment-1030859958>
          "https://autost.cachix.org?priority=41"
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
          cuffs = {
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
      };

      hardware.enableAllFirmware = true;
      hardware.keyboard.zsa.enable = true;

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
        blueman.enable = true;

        openssh = {
          enable = true;
          startWhenNeeded = true;
        };

        logind.extraConfig = ''
          HandlePowerKey=ignore
        '';

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

          # incompatible with ssh.startAgent
          # enableSSHSupport = true;
        };

        ssh.startAgent = true;

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
        nix-doc

        (writeScriptBin "darktable-exported.sh" (readFile ../bin/darktable-exported.sh))
        (writeScriptBin "markdown-photos.sh" (readFile ../bin/markdown-photos.sh))
        (writeScriptBin "midi.sh" (readFile ../bin/midi.sh))
        (writeScriptBin "nef2jpg.sh" (readFile ../bin/nef2jpg.sh))
        (writeScriptBin "photo-details.sh" (readFile ../bin/photo-details.sh))
        (writeScriptBin "rsync.sh" (readFile ../bin/rsync.sh))
        (writeScriptBin "screenshot.sh" (readFile ../bin/screenshot.sh))
        (writeScriptBin "slock" (readFile ../bin/slock))
        (writeScriptBin "smart.sh" (readFile ../bin/smart.sh))
        (writeScriptBin "ssg.sh" (readFile ../bin/ssg.sh))
        (writeScriptBin "sync.sh" (readFile ../bin/sync.sh))
        (writeScriptBin "wine.sh" (readFile ../bin/wine.sh))
        (writeScriptBin "zfs-iostat-totals" (readFile ../bin/zfs-iostat-totals))
        (writeScriptBin "zfs-sync-snapshots" (readFile ../bin/zfs-sync-snapshots))
        (writeScriptBin "zfs-thin-snapshots" (readFile ../bin/zfs-thin-snapshots))

        (writeScriptBin "sync-colo.sh" (readFile ../bin/sync-colo.sh))
        (writeScriptBin "sync-jupiter.sh" (readFile ../bin/sync-jupiter.sh))
        (writeScriptBin "sync-tol.sh" (readFile ../bin/sync-tol.sh))
        (writeScriptBin "sync-venus.sh" (readFile ../bin/sync-venus.sh))

        # <https://git.isincredibly.gay/srxl/gemstone-labs.nix/src/commit/21e905f71929a54b5f5e25ce9dbe2e5cf0bc4fc9/deploy>
        fish
        (writeScriptBin "deploy" (readFile ../bin/deploy))
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
  ];
}
