{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "E897B482";
    hostName = "jupiter";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/${config.internal.hostName}.root";
    bootDevice = "/dev/disk/by-uuid/B2F1-7DD3";
    separateNix = true;
    initialUser = "delan";

    interactive = true;
    laptop = true;
    igalia = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  # hardware-configuration.nix
  swapDevices = [ { device = "/dev/disk/by-uuid/ea77bc52-0937-4695-be03-5ea459a5fba5"; } ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  # merged below # boot.kernelModules = [ "kvm-amd" ];

  nix.settings.sandbox = true;

  hardware.opentabletdriver.enable = true;

  boot.kernelModules = [
    "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"

    # hardware-configuration.nix
    "kvm-amd"
  ];
  boot.kernelParams = [
    "intel_iommu=on" "default_hugepagesz=1G" "hugepagesz=1G"
    "kvm.ignore_msrs=1"

    # https://github.com/NixOS/nixos-hardware/pull/115
    # https://github.com/erpalma/throttled/issues/215
    "msr.allow_writes=on"
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        4000 8000 # default node/python dev
        9800 9801 9802 9803 # more dev (arbitrary)
        3128 3180 # oldssl-proxy
        13367 # qbittorrent torrent (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
      ];

      allowedUDPPorts = [
        13367 # qbittorrent torrent (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    colordiff
    efibootmgr
    file
    gnome3.networkmanager-openvpn
    hdparm
    iftop
    iotop
    lm_sensors
    lsof
    ncdu
    ntfs3g
    pciutils
    tcpdump
    termite
    usbutils
  ];

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  # tdarr node
  programs.fuse.userAllowOther = true;

  # raspberry pi pico
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", MODE:="0666"
  '';

  # hashcat
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # wireshark
  programs.wireshark.enable = true;
  users.users.delan.extraGroups = [ "wireshark" ];
}
