{ config, lib, options, modulesPath, pkgs }: {
  imports = [ ./hardware-configuration.nix ../lib ];

  internal = {
    hostId = "99D8468B";
    hostName = "colo";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/a8b6dd52-8f9f-42f8-badc-53b43aa9a4df";
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    services = {
    };
  };

  boot = {
    kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];

    kernelParams = [
      "intel_iommu=on" # "vfio_pci.ids=1000:0072,10de:13c2,10de:0fbb"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
    ];
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
  ];
}
