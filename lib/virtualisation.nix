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
        enableOnBoot = true;

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
  ];
}
