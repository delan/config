{ config, lib, options, modulesPath, pkgs, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "99D8468B";
    hostName = "venus";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/62d52d15-c5ee-4143-816e-994b0ae4fec4";
    bootDevice = "/dev/disk/by-uuid/3A36-D233";
    separateNix = false;
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    services = {
      collectd = false;
      jackett = false;
      jellyfin = false;
    };
  };

  # hardware-configuration.nix
  # merged below # boot.kernelModules = [ "kvm-intel" ];
  # merged below # boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "vfio_pci" "usbhid" "sd_mod" ];
  nix.settings.max-jobs = lib.mkDefault 8;

  boot = {
    initrd.luks.devices = {
      ocean0x0 = { device = "/dev/disk/by-partlabel/ocean0x0"; };
      ocean0x1 = { device = "/dev/disk/by-partlabel/ocean0x1"; };
      ocean1x0 = { device = "/dev/disk/by-partlabel/ocean1x0"; };
      ocean1x1 = { device = "/dev/disk/by-partlabel/ocean1x1"; };
      ocean2x0 = { device = "/dev/disk/by-partlabel/ocean2x0"; };
      ocean2x2 = { device = "/dev/disk/by-partlabel/ocean2x2"; };
      ocean3x0 = { device = "/dev/disk/by-partlabel/ocean3x0"; };
      ocean3x1 = { device = "/dev/disk/by-partlabel/ocean3x1"; };
      ocean4x0 = { device = "/dev/disk/by-partlabel/ocean4x0"; };
      ocean4x1 = { device = "/dev/disk/by-partlabel/ocean4x1"; };
      oceanSx0 = { device = "/dev/disk/by-partlabel/oceanSx0"; };
      oceanSx1 = { device = "/dev/disk/by-partlabel/oceanSx1"; };
      "ocean.arc" = { device = "/dev/disk/by-partlabel/ocean.arc"; };
    };

    kernelModules = [
      "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"

      # hardware-configuration.nix
      "kvm-intel"
    ];

    initrd.availableKernelModules = [
      # for luks password
      "hid-microsoft"

      # hardware-configuration.nix
      "xhci_pci" "ehci_pci" "ahci" "vfio_pci" "usbhid" "sd_mod"
    ];

    kernelParams = [
      "intel_iommu=on" "vfio_pci.ids=1000:0072,10de:13c2,10de:0fbb"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=20"
      ####### "isolcpus=0,4,1,5" "nohz_full=0,4,1,5" "rcu_nocbs=0,4,1,5"

      # for GPU-Z https://www.reddit.com/r/VFIO/comments/ahg1ta
      "kvm.ignore_msrs=1"
    ];

    # for VMware https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
    extraModprobeConfig = "options kvm_intel nested=1";

    # https://sholland.org/2016/howto-pass-usb-ports-to-kvm/
    # (0x3ff7 /* webcam */ & 0x3fef /* mouse */ & 0x3fdf /* keyboard */ & 0x3eff /* dac */ /* & 0x3bff /* bmc */).toString(16)
    # ~(0x0008 /* webcam */ | 0x0010 /* mouse */ | 0x0020 /* keyboard */ | 0x0100 /* dac */ /* | 0x0400 /* bmc */).toString(16)
    initrd.extraUtilsCommands = "copy_bin_and_libs ${pkgs.pciutils}/bin/setpci";
    # initrd.preDeviceCommands = "setpci -s0:14.0 0xd0.W=0x3ec7";
    # postBootCommands = "/run/current-system/sw/bin/setpci -s0:14.0 0xd0.W=0x3ec7";
  };

  # fileSystems."/mnt/ocean/active" = {
    # device = "vtnet1.storage.daz.cat.:/ocean/active";
    # device = "172.19.129.205:/ocean/active";
    # fsType = "nfs";
    # options = [ "noauto" "ro" "vers=3" "soft" "bg" ];
  # };

  # fileSystems."/mnt/ocean/public" = {
    # device = "vtnet1.storage.daz.cat.:/ocean/public";
    # device = "127.0.0.1:/ocean/public";
    # fsType = "nfs";
    # options = [ "noauto" "ro" "vers=4" "soft" "bg" "sec=krb5p" ];
  # };

  environment.systemPackages = with pkgs; [
    tmux htop pv vim iperf3 neovim

    # nix-locate(1)
    nix-index

    # hardware stuff
    pciutils usbutils ipmitool lm_sensors

    # virt-clone(1)
    virtmanager

    atool
    bc
    clang
    gcc
    colordiff
    file
    git
    gnumake
    iftop
    lazygit
    # lsiutil # TODO upgrade nixos first?
    neofetch
    nmap
    ntfs3g
    openiscsi
    ripgrep
    sg3_utils
    smartmontools
    steam-run
    unzip
  ];

  services.cron = {
    enable = true;
    systemCronJobs = ["0 21 * * * root BUSTED_WEBHOOK=https://discord.com/api/webhooks/1167804331068760064/redacted ~delan/bin/sync.sh"];
  };

  # for sshfs -o allow_other,default_permissions,idmap=user
  programs.fuse.userAllowOther = true;

  networking.firewall.allowedTCPPorts = [
    8123 # home-assistant
    7474 # autobrr
    1313 # zfs send

    111 2049 # nfs
  ];
  networking.firewall.allowedUDPPorts = [
    111 2049 # nfs
  ];

  services.nfs.server = {
    enable = true;
    exports = ''
      # 172.19.42.33 = nyaaa
      /ocean 172.19.42.33(ro,all_squash)
      /ocean/active 172.19.42.33(ro,all_squash)
    '';
  };

  users.users.aria = {
    isNormalUser = true;
    uid = 1001;
    shell = pkgs.zsh;
    extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
    initialHashedPassword = "$6$4NkWaZ7Un5r.CR2C$I22bgLqKU2DxlNye4jEicYmV06BFjcwe60q.cigaTQjeviYK0Aq7MITV09koexPSBPdvsibIxYo0rYwOJ7dlg0"; # hunter2
  };
}
