{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.virtualisation = {
    libvirt = mkOption { type = types.bool; default = false; };
    docker = mkOption { type = types.bool; default = false; };
    virtualbox = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal;
  in mkMerge [
    (mkIf cfg.virtualisation.libvirt (mkMerge [
      {
        virtualisation.libvirtd = {
          enable = true;
          qemuRunAsRoot = false;
          onShutdown = "shutdown";
        };

        users.users."${config.internal.initialUser}".extraGroups = [ "libvirtd" ];
      }

      (mkIf cfg.interactive {
        environment.systemPackages = with pkgs; [ virt-manager gnome3.dconf ];
        programs.dconf.enable = true;
      })
    ]))

    (mkIf cfg.virtualisation.docker {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = false;
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
  ];
}
