{ config, pkgs, lib, options, modulesPath }: {
  imports = [ ./lib ];

  internal = {
    hostId = "7A27D153";
    hostName = "saturn";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/8efbbe49-29d8-4969-8d75-fbf822c6938f";
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    interactive = true;
    laptop = true;
  };

  environment.systemPackages = with pkgs; [
    # TODO interactive + virtualisation.libvirt
    # for virt-manager (NixOS/nixpkgs#2448)
    gnome3.dconf

    # for nm-applet (to store AnyConnect secrets)
    gcr gnome3.defaultIconTheme
  ];
}
