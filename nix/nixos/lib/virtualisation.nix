{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.virtualisation = {
    libvirt = mkOption { type = types.bool; default = false; };
    docker = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal.virtualisation;
  in mkMerge [
    (mkIf cfg.libvirt {
      virtualisation.libvirtd = {
        enable = true;
        qemuRunAsRoot = false;
        onShutdown = "shutdown";
      };

      users.users."${config.internal.initialUser}".extraGroups = [ "libvirtd" ];

      # TODO interactive only
      # for virt-manager (NixOS/nixpkgs#2448)
      environment.systemPackages = [ pkgs.virt-manager pkgs.gnome3.dconf ];
      programs.dconf.enable = true;
    })

    (mkIf cfg.docker {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = false;
      };

      users.users."${config.internal.initialUser}".extraGroups = [ "docker" ];
    })
  ];
}
