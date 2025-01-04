{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ./interactive.nix
    ./laptop.nix
    ./igalia.nix
    ./virtualisation.nix
    ./services
    ./programs
  ];

  options.internal = {
    hostId = mkOption { type = types.str; };
    hostName = mkOption { type = types.str; };
    domain = mkOption { type = types.str; };
    luksDevice = mkOption { type = types.str; };
    bootDevice = mkOption { type = types.str; };
    swapDevice = mkOption { type = types.nullOr types.str; };
    separateNix = mkOption { type = types.bool; };
    initialUser = mkOption { type = types.str; };
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
    {
      networking.hostId = config.internal.hostId;
      networking.hostName = config.internal.hostName;
      networking.domain = config.internal.domain;
      system.stateVersion = "18.09";

      fileSystems = {
        "/" = { device = "cuffs/root"; fsType = "zfs"; };
        "/home" = { device = "cuffs/home"; fsType = "zfs"; };
        "/boot" = { device = cfg.bootDevice; fsType = "vfat"; };
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
      nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];
      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';
      nix.settings = {
        sandbox = true;
        substituters = [
          "https://autost.cachix.org"
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

      services = {
        fwupd.enable = true;

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

        (writeScriptBin "midi.sh" (readFile ../bin/midi.sh))
        (writeScriptBin "screenshot.sh" (readFile ../bin/screenshot.sh))
        (writeScriptBin "smart.sh" (readFile ../bin/smart.sh))
        (writeScriptBin "ssg.sh" (readFile ../bin/ssg.sh))
        (writeScriptBin "sync.sh" (readFile ../bin/sync.sh))
        (writeScriptBin "zfs-iostat-totals" (readFile ../bin/zfs-iostat-totals))
        (writeScriptBin "zfs-sync-snapshots" (readFile ../bin/zfs-sync-snapshots))
        (writeScriptBin "zfs-thin-snapshots" (readFile ../bin/zfs-thin-snapshots))

        (writeScriptBin "sync-colo.sh" (readFile ../bin/sync-colo.sh))
        (writeScriptBin "sync-jupiter.sh" (readFile ../bin/sync-jupiter.sh))
        (writeScriptBin "sync-tol.sh" (readFile ../bin/sync-tol.sh))
        (writeScriptBin "sync-venus.sh" (readFile ../bin/sync-venus.sh))

        # <https://git.isincredibly.gay/srxl/gemstone-labs.nix/src/commit/21e905f71929a54b5f5e25ce9dbe2e5cf0bc4fc9/deploy>
        fish
        (writeScriptBin "deploy" ''
          #!/usr/bin/env fish
          # Author: Ruby Iris Juric <ruby@srxl.me>

          function show_help
              echo "deploy - Simple nixos-rebuild wrapper for deploying remote machines"
              echo ""
              echo "Usage: ./deploy [-h] [-s ssh_server] hostname [rebuild_args]"
              echo "Flags:"
              echo "  -h/--help: Show this message"
              echo "  -n/--new:  Deploy to a newly provisioned machine"
              echo "  -s/--ssh:  The SSH address to deploy to. Defaults to the expression name if not supplied"
              echo "  "
              echo "Examples:"
              echo "  Deploy to a machine called \"foo\":"
              echo "  ./deploy foo"
              echo ""
              echo "  Deploy the \"foo\" configuration to a particular IP address:"
              echo "  ./deploy -s 10.0.2.123 foo"
              echo ""
              echo "  Run \"nixos-rebuild -L test\" on \"foo\":"
              echo "  ./deploy foo -L test"
              exit
          end

          argparse --name=deploy -i h/help n/new 's/ssh=' -- $argv
          or return

          if [ -n "$_flag_h" ]
              show_help
          end

          if [ -n "$_flag_s" ]
              set host $_flag_s
          else if [ -n "$_flag_n" ]
              set host gemstone-labs-new-deploy-target
          else
              set host $argv[1]
          end

          if [ -z "$argv[1]" ]
              echo "deploy: machine name must be specified"
              exit 1
          end

          if [ -n "$argv[2..]" ]
              set cmd $argv[2..]
          else
              set cmd switch
          end

          set -x NIX_SSHOPTS -t

          if [ $host = gemstone-labs-new-deploy-target ]
              set -a NIX_SSHOPTS "-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
              sleep 10
          end

          nixos-rebuild --fast --use-remote-sudo --target-host root@$host --log-format internal-json -v --flake .#$argv[1] $cmd &| nom --json

          if [ $host = gsl-new-deploy-target ]
              ssh $NIX_SSHOPTS root@$host reboot
          end
        '')
      ];
    }
  ];
}
