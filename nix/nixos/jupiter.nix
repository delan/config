{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ ./lib ];

  internal = {
    hostId = "E897B482";
    hostName = "jupiter";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    initialUser = "delan";

    interactive = true;
    laptop = true;
    igalia = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  nix.useSandbox = true;

  hardware.opentabletdriver.enable = true;

  boot.kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];
  boot.kernelParams = [
    "intel_iommu=on" "default_hugepagesz=1G" "hugepagesz=1G"
    "kvm.ignore_msrs=1"

    # https://github.com/NixOS/nixos-hardware/pull/115
    # https://github.com/erpalma/throttled/issues/215
    "msr.allow_writes=on"
  ];
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  networking = {
    firewall = {
      allowedTCPPorts = [
        4000 8000 # default node/python dev
        9800 9801 9802 9803 # more dev (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
        3128 3180 # oldssl-proxy
        9222 # cros
        3000 # bloomberg 2022-10-tks-scrolling-on-web-master
      ];

      allowedUDPPorts = [
        13368 13369 # aria2 torrent (arbitrary)
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    file ncdu lsof colordiff efibootmgr termite pciutils usbutils ntfs3g
    gnome3.networkmanager-openvpn
    iftop tcpdump
    iotop hdparm
  ];

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  # tdarr node
  programs.fuse.userAllowOther = true;

  # raspberry pi pico
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", MODE:="0666"
  '';
}
