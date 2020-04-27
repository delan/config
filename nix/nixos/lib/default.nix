{ config, lib, options, modulesPath, pkgs }: with lib; {
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
    time.timeZone = "Australia/Sydney";

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
      supportedFilesystems = [ "zfs" ];

      # kernelPackages = pkgs.linuxPackages_latest;
      # zfs.enableUnstable = true;
    };

    networking = {
      networkmanager = {
        enable = true;
        # extraConfig = ''
        #   [logging]
        #   domains=VPN:TRACE,AGENTS:TRACE
        # '';
      };

      # fucking breaks everything
      dhcpcd.enable = false;
    };

    networking.hosts = {
      # TODO document
      # "151.101.82.217" = [ "cache.nixos.org" ];
    };

    services = {
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

        extraConfig = ''
          server:
          use-caps-for-id: yes
          qname-minimisation: yes
          # qname-minimisation-strict: yes

          local-zone: '128.19.172.in-addr.arpa.' always_transparent
          local-zone: '129.19.172.in-addr.arpa.' always_transparent
          local-zone: 'e.c.9.2.2.2.3.4.f.e.9.0.6.3.d.f.ip6.arpa.' always_transparent

          # stub-zone:
          # name: 'internal.atlassian.com'
          # stub-addr: 10.53.53.53

          # stub-zone:
          # name: 'buildeng.atlassian.com'
          # stub-addr: 10.53.53.53

          # stub-zone:
          # name: 'media.atlassian.com'
          # stub-addr: 10.53.53.53

          # stub-zone:
          # name: 'stash.atlassian.com'
          # stub-addr: 10.53.53.53

          stub-zone:
          name: '128.19.172.in-addr.arpa.'
          stub-host: 'daria.daz.cat.'

          stub-zone:
          name: '129.19.172.in-addr.arpa.'
          stub-host: 'daria.daz.cat.'

          stub-zone:
          name: 'e.c.9.2.2.2.3.4.f.e.9.0.6.3.d.f.ip6.arpa.'
          stub-host: 'daria.daz.cat.'
        '';
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
        enableSSHSupport = true;
      };
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
