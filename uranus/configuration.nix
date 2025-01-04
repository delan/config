{ config, pkgs, lib, options, modulesPath }: {
  imports = [ ./hardware-configuration.nix ../lib ];

  internal = {
    hostId = "2C562D26";
    hostName = "uranus";
    domain = "daz.cat";
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
    # for nm-applet (to store AnyConnect secrets)
    gcr gnome3.defaultIconTheme
  ];
}
