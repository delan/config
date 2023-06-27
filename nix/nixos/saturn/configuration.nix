{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ /config/nix/nixos/saturn/hardware-configuration.nix ../lib ];

  internal = {
    hostId = "7A27D153";
    hostName = "saturn";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/8efbbe49-29d8-4969-8d75-fbf822c6938f";
    initialUser = "delan";

    interactive = true;
    laptop = true;
    igalia = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  nix.settings.sandbox = true;

  # biggest(?) available font
  console.font = "iso01-12x22";

  # https://nixos.wiki/wiki/Nvidia#sync_mode
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.prime = {
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  # FIXME only done for debugging X11 ABI problem?
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;

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
        34197 # factorio
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
}
