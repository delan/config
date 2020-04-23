{ config, pkgs, lib, options, modulesPath }: {
  imports = [ ./lib ];

  internal = {
    hostName = "uranus.daz.cat";
    hostId = "2C562D26";
    luksDevice = "/dev/disk/by-uuid/591f63f0-a756-4696-b68c-784749e3dff7";
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
