{ config, lib, options, modulesPath, pkgs }: {
  imports = [ ./lib ];

  internal = {
    hostName = "venus.daz.cat";
    hostId = "99D8468B";
    luksDevice = "/dev/disk/by-uuid/62d52d15-c5ee-4143-816e-994b0ae4fec4";
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    services = {
      collectd = true;
      jackett = true;
      jellyfin = true;
    };
  };

  boot = {
    kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];

    kernelParams = [
      "intel_iommu=on" "vfio_pci.ids=1000:0072,10de:13c2,10de:0fbb"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
      ####### "isolcpus=0,4,1,5" "nohz_full=0,4,1,5" "rcu_nocbs=0,4,1,5"

      # for GPU-Z https://www.reddit.com/r/VFIO/comments/ahg1ta
      "kvm.ignore_msrs=1"
    ];

    # for VMware https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
    extraModprobeConfig = "options kvm_intel nested=1";

    # https://sholland.org/2016/howto-pass-usb-ports-to-kvm/
    postBootCommands = "setpci -s0:14.0 0xd0.W=0x3bff";
  };

  fileSystems."/mnt/ocean/active" = {
    # device = "vtnet1.storage.daz.cat.:/ocean/active";
    device = "172.19.129.205:/ocean/active";
    fsType = "nfs";
    options = [ "noauto" "ro" "vers=3" "soft" "bg" ];
  };

  environment.systemPackages = with pkgs; [
    tmux htop pv vim iperf3
    # openiscsi sg3_utils

    # nix-locate(1)
    nix-index

    # hardware stuff
    pciutils usbutils ipmitool lm_sensors

    # virt-clone(1)
    virtmanager

    # for rust
    # clang binutils
  ];
}
