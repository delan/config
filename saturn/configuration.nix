{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "7A27D153";
    hostName = "saturn";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/saturn.cuffs";
    bootDevice = "/dev/disk/by-partlabel/saturn.esp";
    swapDevice = "/dev/disk/by-partlabel/saturn.swap";
    separateNix = true;
    initialUser = "delan";

    interactive = true;
    laptop = true;
    igalia = true;
    tailscale = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  nix.settings.sandbox = true;

  # biggest(?) available font
  console.font = "iso01-12x22";

  # https://nixos.wiki/wiki/Nvidia#Disable_Nvidia_dGPU_completely
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];

  hardware.opentabletdriver.enable = true;

  boot.kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];
  boot.kernelParams = [
    "intel_iommu=on" "default_hugepagesz=1G" "hugepagesz=1G"
    "kvm.ignore_msrs=1"

    # https://github.com/NixOS/nixos-hardware/pull/115
    # https://github.com/erpalma/throttled/issues/215
    "msr.allow_writes=on"
  ];
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1

    # https://nixos.wiki/wiki/Nvidia#Disable_Nvidia_dGPU_completely
    blacklist nouveau
    options nouveau modeset=0
  '';

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
    cifs-utils
    colordiff
    efibootmgr
    file
    gh  # for servo
    networkmanager-openvpn
    hdparm
    iftop
    iotop
    lm_sensors
    lsof
    ncdu
    ntfs3g
    pciutils
    samba
    tcpdump
    termite
    usbutils
  ];

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  # tdarr node
  programs.fuse.userAllowOther = true;

  services.udev.extraRules = ''
    # raspberry pi pico
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", MODE:="0666"

    # luna usb debugger
    SUBSYSTEMS=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615c", MODE:="0666"
    SUBSYSTEMS=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615b", MODE:="0666"

    # fx2la
    SUBSYSTEMS=="usb", ATTR{idVendor}=="0925", ATTR{idProduct}=="3881", MODE:="0666"

    # https://nixos.wiki/wiki/Nvidia#Disable_Nvidia_dGPU_completely
    # Remove NVIDIA USB xHCI Host Controller devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA USB Type-C UCSI devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA Audio devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA VGA/3D controller devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  '';
}
