{ config, pkgs, lib, options, modulesPath, ... }:
let
  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts  
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };
in {
  imports = [ ../lib ];

  internal = {
    hostId = "E897B482";
    hostName = "jupiter";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/jupiter.root";
    bootDevice = "/dev/disk/by-uuid/B2F1-7DD3";
    swapDevice = "/dev/disk/by-partlabel/jupiter.swap";
    separateNix = true;
    initialUser = "delan";

    interactive = true;
    laptop = false;
    igalia = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  # hardware-configuration.nix
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  # merged below # boot.kernelModules = [ "kvm-amd" ];

  # amdgpu
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  # hardware.opengl.extraPackages = [
  #   # hashcat
  #   pkgs.rocm-opencl-icd
  #   pkgs.rocm-opencl-runtime
  #
  #   pkgs.mesa.drivers pkgs.amdvlk
  # ];
  hardware.graphics.extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];

  # for servo amd disable boost
  # https://docs.kernel.org/admin-guide/pm/cpufreq.html#frequency-boost-support
  # https://lwn.net/Articles/979398/
  boot.kernelPackages = pkgs.linuxPackages_6_11;

  hardware.opentabletdriver.enable = true;

  boot.kernelModules = [
    "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"

    # hardware-configuration.nix
    "kvm-amd"
  ];
  boot.kernelParams = [
    "intel_iommu=on" "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=48"
    "kvm.ignore_msrs=1"

    # https://github.com/NixOS/nixos-hardware/pull/115
    # https://github.com/erpalma/throttled/issues/215
    "msr.allow_writes=on"
  ];
  boot.initrd.luks.devices = {
    cuffs1x0 = {
      device = "/dev/disk/by-partlabel/jupiter.cuffs1x0";
    };
  };

  fileSystems."/ocean" = {
    device = "venus.tailcdc44b.ts.net.:/ocean";
    fsType = "nfs";
    options = [ "rw" "soft" "bg" ];
  };
  fileSystems."/ocean/active" = {
    device = "venus.tailcdc44b.ts.net.:/ocean/active";
    fsType = "nfs";
    options = [ "rw" "soft" "bg" ];
  };
  fileSystems."/ocean/private" = {
    device = "venus.tailcdc44b.ts.net.:/ocean/private";
    fsType = "nfs";
    options = [ "rw" "soft" "bg" ];
  };
  fileSystems."/ocean/public" = {
    device = "venus.tailcdc44b.ts.net.:/ocean/public";
    fsType = "nfs";
    options = [ "rw" "soft" "bg" ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        21 # pyftpdlib
        4000 8000 8080 # default node/python dev
        9800 9801 9802 9803 # more dev (arbitrary)
        3128 3180 # oldssl-proxy
        13367 # qbittorrent torrent (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
        20300 # servo ci monitor test (public!)
      ];

      allowedUDPPorts = [
        13367 # qbittorrent torrent (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    cdrkit  # for servo/ci-runners
    colordiff
    cpuset  # for servo perf testing
    dbus-sway-environment
    efibootmgr
    file
    gh  # for servo/ci-runners
    networkmanager-openvpn
    hdparm
    hivex  # for servo/ci-runners
    iftop
    iotop
    jq  # for servo/ci-runners
    lm_sensors
    lsof
    mitmproxy  # for servo/perf-analysis-tools
    ncdu
    ntfs3g
    pciutils
    tcpdump
    termite
    unzip  # for servo/ci-runners
    usbutils
  ];

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  # tdarr node
  programs.fuse.userAllowOther = true;

  # wireshark
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark-qt;
  users.users.delan.extraGroups = [ "wireshark" ];

  services.cron = {
    enable = true;
    systemCronJobs = ["0 21 * * * root BUSTED_WEBHOOK=https://discord.com/api/webhooks/1167804331068760064/redacted ~delan/bin/sync.sh"];
  };

  programs.sway.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  users.groups.plugdev = {};
  # FIXME this commit is now 404
  # services.udev.packages = with import (builtins.fetchTarball {
  #   # NixOS/nixpkgs#237313 = ppenguin:refactor-platformio-fix-ide
  #   url = "https://github.com/NixOS/nixpkgs/archive/3592b10a67b518700002f1577e301d73905704fe.tar.gz";
  #   sha256 = "135sxn5xxw4dl8hli4k6c9rwpllwghwh0pnhvn4bh988rzybzc6z";
  # }) {
  #   system = "x86_64-linux";
  # }; [
  #   platformio-core
  #   openocd
  # ];

  # TODO s/wheel/plugdev/
  services.udev.extraRules = ''
    # raspberry pi pico
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", MODE:="0666"

    # pine64 usb->ttl
    SUBSYSTEMS=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE:="0666"

    # luna usb debugger
    SUBSYSTEMS=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615c", MODE:="0666"
    SUBSYSTEMS=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615b", MODE:="0666"

    # Rules for Oryx web flashing and live training
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="wheel"
    KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="wheel"

    # Legacy rules for live training over webusb (Not needed for firmware v21+)
      # Rule for all ZSA keyboards
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="wheel"
      # Rule for the Moonlander
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="wheel"
      # Rule for the Ergodox EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="wheel"
      # Rule for the Planck EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="wheel"

    # Wally Flashing rules for the Ergodox EZ
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

    # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
    # Keymapp Flashing rules for the Voyager
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
  '';

  services.openssh.settings.X11Forwarding = true;

  # servo benchmarking
  users.groups.mitmproxy = {
    members = [ "delan" ];
  };

  # servo/perf-analysis-tools
  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [
      { options = [ "NOPASSWD" ]; command = "/home/delan/code/servo/attic/perf/analyse/isolate-cpu-for-shell.sh"; }
    ];
  }];

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
