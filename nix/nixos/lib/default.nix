{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ../hardware-configuration.nix
    ./interactive.nix
    ./virtualisation.nix
    ./laptop.nix
    ./services
  ];

  options.internal = {
    hostId = mkOption { type = types.str; };
    hostName = mkOption { type = types.str; };
    domain = mkOption { type = types.str; };
    luksDevice = mkOption { type = types.str; };
    initialUser = mkOption { type = types.str; };
  };

  config = {
    networking.hostId = config.internal.hostId;
    networking.hostName = config.internal.hostName;
    networking.domain = config.internal.domain;
    system.stateVersion = "18.09";

    users.users."${config.internal.initialUser}" = {
      isNormalUser = true;
      uid = 1000;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "systemd-journal" "networkmanager" ];

      # hunter2
      initialHashedPassword = "$6$4NkWaZ7Un5r.CR2C$I22bgLqKU2DxlNye4jEicYmV06BFjcwe60q.cigaTQjeviYK0Aq7MITV09koexPSBPdvsibIxYo0rYwOJ7dlg0";
    };

    nixpkgs.config.allowUnfree = true;

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

      cleanTmpDir = true;
      supportedFilesystems = [ "zfs" "xfs" ];

      kernel.sysctl = {
        # enable all magic sysrq functions
        # https://github.com/NixOS/nixpkgs/issues/83694
        # https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
        "kernel.sysrq" = 1;
      };
    };

    hardware.keyboard.zsa.enable = true;

    networking = {
      networkmanager.enable = true;

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
        enable = true;

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
          stub-zone = [
            { name = "local.igalia.com."; stub-addr = "192.168.10.14"; }
            { name = "10.168.192.in-addr.arpa."; stub-addr = "192.168.10.14"; }
          ];
        };
      };

      avahi = {
        enable = true;
        nssmdns = true;
        ipv6 = true;
        publish = {
          enable = true;
          addresses = true;
          domain = true;
        };
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
      ];
    }];
  };
}
