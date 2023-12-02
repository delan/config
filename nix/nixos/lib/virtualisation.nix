{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.virtualisation = {
    libvirt = mkOption { type = types.bool; default = false; };
    docker = mkOption { type = types.bool; default = false; };
    virtualbox = mkOption { type = types.bool; default = false; };
    vmware = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkMerge [
    (mkIf cfg.virtualisation.libvirt (mkMerge [
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu.runAsRoot = false;
          onShutdown = "shutdown";
          allowedBridges = [ "virbr0" "virbr1" "bridge13" ];
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
        daemon = {
          settings = {
            storage-driver = "overlay2";
            ipv6 = true;
            fixed-cidr-v6 = "fd39:9aa4:efad::/80";
            experimental = true;
            ip6tables = true;
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
  ];
}
