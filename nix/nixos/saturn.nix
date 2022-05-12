{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ <nixos-hardware/lenovo/thinkpad/x1-extreme/gen2> ./lib ];

  internal = {
    hostId = "7A27D153";
    hostName = "saturn";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-uuid/8efbbe49-29d8-4969-8d75-fbf822c6938f";
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    interactive = true;
    laptop = true;
  };

  # dunno lol
  # hardware.bumblebee.enable = true;

  # intel only: no configuration needed

  # dedicated only
  # services.xserver.videoDrivers = [ "nvidia" ];

  # https://nixos.wiki/wiki/Nvidia#sync_mode
  # https://nixos.wiki/wiki/Nvidia#offload_mode
  # services.xserver.videoDrivers = [ "modesetting" "nvidia" ]; # does not work
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.prime = {
    sync.enable = true;
    # offload.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    intelBusId = "PCI:0:2:0";
  };

  boot.kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];
  boot.kernelParams = [
    "intel_iommu=on" "default_hugepagesz=1G" "hugepagesz=1G" ### "hugepages=8"
    ### "isolcpus=1-5,7-11" "rcu_nocbs=1-5,7-11" ### "nohz_full=1-5,7-11"
    "kvm.ignore_msrs=1"

    # https://github.com/NixOS/nixos-hardware/pull/115
    # https://github.com/erpalma/throttled/issues/215
    "msr.allow_writes=on"
  ];
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  environment.systemPackages = with pkgs; [
    # for nm-applet (to store AnyConnect secrets)
    gcr gnome3.defaultIconTheme
  ];
}
