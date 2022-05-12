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

  nix.useSandbox = true;

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

  # 32-bit game support
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  fileSystems."/mnt/ocean/active" = {
    # device = "vtnet1.storage.daz.cat.:/ocean/active";
    device = "172.19.42.179:/ocean/active";
    fsType = "nfs";
    options = [ "noauto" "ro" "vers=3" "soft" "bg" ];
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

  networking = {
    firewall = {
      allowedTCPPorts = [
        139 445 # samba
        4000 8000 # default node/python dev
        9800 9801 9802 9803 # more dev (arbitrary)
        13368 13369 # aria2 torrent (arbitrary)
      ];

      allowedUDPPorts = [
        137 138 # samba
        13368 13369 # aria2 torrent (arbitrary)
      ];
    };

    hosts = {
      "127.0.0.1" = [
        "www1.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "op88.web-platform.test"
        "op36.not-web-platform.test"
        "op53.not-web-platform.test"
        "op50.not-web-platform.test"
        "xn--lve-6lad.www.web-platform.test"
        "op98.web-platform.test"
        "op24.not-web-platform.test"
        "op31.not-web-platform.test"
        "op95.not-web-platform.test"
        "op85.web-platform.test"
        "op83.not-web-platform.test"
        "www2.not-web-platform.test"
        "xn--lve-6lad.www.not-web-platform.test"
        "op73.not-web-platform.test"
        "op8.web-platform.test"
        "www2.www2.not-web-platform.test"
        "op89.web-platform.test"
        "op66.web-platform.test"
        "xn--lve-6lad.web-platform.test"
        "op19.not-web-platform.test"
        "www1.www2.web-platform.test"
        "op72.web-platform.test"
        "op24.web-platform.test"
        "op21.not-web-platform.test"
        "xn--lve-6lad.not-web-platform.test"
        "op41.web-platform.test"
        "op79.web-platform.test"
        "op81.not-web-platform.test"
        "op70.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.xn--lve-6lad.not-web-platform.test"
        "op78.not-web-platform.test"
        "op6.not-web-platform.test"
        "www1.www.not-web-platform.test"
        "op40.not-web-platform.test"
        "op25.not-web-platform.test"
        "op3.not-web-platform.test"
        "op65.not-web-platform.test"
        "op91.web-platform.test"
        "www.www2.web-platform.test"
        "op80.not-web-platform.test"
        "op59.web-platform.test"
        "op52.not-web-platform.test"
        "xn--lve-6lad.xn--lve-6lad.web-platform.test"
        "op68.not-web-platform.test"
        "op45.not-web-platform.test"
        "op71.not-web-platform.test"
        "op72.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www2.web-platform.test"
        "op39.web-platform.test"
        "op90.not-web-platform.test"
        "op60.web-platform.test"
        "op58.web-platform.test"
        "op28.web-platform.test"
        "www1.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.xn--lve-6lad.web-platform.test"
        "op14.web-platform.test"
        "op89.not-web-platform.test"
        "op69.web-platform.test"
        "op49.not-web-platform.test"
        "op40.web-platform.test"
        "op2.not-web-platform.test"
        "op5.not-web-platform.test"
        "www.www2.not-web-platform.test"
        "op77.not-web-platform.test"
        "www.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "op7.web-platform.test"
        "op74.web-platform.test"
        "op79.not-web-platform.test"
        "op82.not-web-platform.test"
        "www.www1.web-platform.test"
        "op12.not-web-platform.test"
        "op39.not-web-platform.test"
        "op31.web-platform.test"
        "www.not-web-platform.test"
        "www.www.not-web-platform.test"
        "op44.not-web-platform.test"
        "www1.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www1.web-platform.test"
        "op58.not-web-platform.test"
        "op14.not-web-platform.test"
        "op30.not-web-platform.test"
        "op62.not-web-platform.test"
        "op61.not-web-platform.test"
        "op92.not-web-platform.test"
        "www2.xn--lve-6lad.web-platform.test"
        "op29.not-web-platform.test"
        "op18.web-platform.test"
        "op73.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "op77.web-platform.test"
        "op12.web-platform.test"
        "op54.web-platform.test"
        "op63.web-platform.test"
        "op71.web-platform.test"
        "www2.www1.not-web-platform.test"
        "op95.web-platform.test"
        "op16.web-platform.test"
        "op36.web-platform.test"
        "op27.web-platform.test"
        "www.www.web-platform.test"
        "op98.not-web-platform.test"
        "op64.not-web-platform.test"
        "op29.web-platform.test"
        "op9.web-platform.test"
        "op26.not-web-platform.test"
        "op22.not-web-platform.test"
        "op94.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www2.not-web-platform.test"
        "op44.web-platform.test"
        "op94.not-web-platform.test"
        "op33.web-platform.test"
        "op38.not-web-platform.test"
        "op33.not-web-platform.test"
        "op84.web-platform.test"
        "www1.www1.not-web-platform.test"
        "op23.not-web-platform.test"
        "op57.not-web-platform.test"
        "op54.not-web-platform.test"
        "op85.not-web-platform.test"
        "www2.www2.web-platform.test"
        "op46.not-web-platform.test"
        "op97.not-web-platform.test"
        "op32.web-platform.test"
        "op61.web-platform.test"
        "op70.web-platform.test"
        "www2.web-platform.test"
        "op32.not-web-platform.test"
        "op60.not-web-platform.test"
        "op4.web-platform.test"
        "op43.web-platform.test"
        "op7.not-web-platform.test"
        "op78.web-platform.test"
        "op26.web-platform.test"
        "xn--lve-6lad.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "op96.not-web-platform.test"
        "op51.not-web-platform.test"
        "op41.not-web-platform.test"
        "op76.web-platform.test"
        "op52.web-platform.test"
        "op99.web-platform.test"
        "op35.not-web-platform.test"
        "op99.not-web-platform.test"
        "op86.web-platform.test"
        "not-web-platform.test"
        "op42.not-web-platform.test"
        "op46.web-platform.test"
        "op67.not-web-platform.test"
        "op17.web-platform.test"
        "op90.web-platform.test"
        "op93.web-platform.test"
        "op37.not-web-platform.test"
        "op48.not-web-platform.test"
        "op10.web-platform.test"
        "op55.not-web-platform.test"
        "op4.not-web-platform.test"
        "www1.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "op55.web-platform.test"
        "xn--lve-6lad.www2.web-platform.test"
        "op47.web-platform.test"
        "op51.web-platform.test"
        "op45.web-platform.test"
        "op80.web-platform.test"
        "op68.web-platform.test"
        "op49.web-platform.test"
        "op57.web-platform.test"
        "www2.xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "www.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "op56.not-web-platform.test"
        "web-platform.test"
        "op84.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "xn--lve-6lad.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "op34.not-web-platform.test"
        "op6.web-platform.test"
        "op35.web-platform.test"
        "op67.web-platform.test"
        "op69.not-web-platform.test"
        "op11.not-web-platform.test"
        "op93.not-web-platform.test"
        "www1.www.web-platform.test"
        "op86.not-web-platform.test"
        "op8.not-web-platform.test"
        "www2.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "op92.web-platform.test"
        "xn--lve-6lad.www1.not-web-platform.test"
        "op15.web-platform.test"
        "op13.not-web-platform.test"
        "op13.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www.web-platform.test"
        "op75.web-platform.test"
        "op20.not-web-platform.test"
        "op76.not-web-platform.test"
        "op64.web-platform.test"
        "op97.web-platform.test"
        "op37.web-platform.test"
        "op56.web-platform.test"
        "op62.web-platform.test"
        "op82.web-platform.test"
        "op25.web-platform.test"
        "op11.web-platform.test"
        "www.xn--lve-6lad.not-web-platform.test"
        "www2.www1.web-platform.test"
        "op27.not-web-platform.test"
        "op50.web-platform.test"
        "op17.not-web-platform.test"
        "op38.web-platform.test"
        "www2.www.not-web-platform.test"
        "xn--lve-6lad.www1.web-platform.test"
        "op75.not-web-platform.test"
        "op83.web-platform.test"
        "op81.web-platform.test"
        "op15.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www.not-web-platform.test"
        "op20.web-platform.test"
        "op3.web-platform.test"
        "www1.www2.not-web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.xn--n8j6ds53lwwkrqhv28a.not-web-platform.test"
        "op2.web-platform.test"
        "op21.web-platform.test"
        "op23.web-platform.test"
        "op42.web-platform.test"
        "op47.not-web-platform.test"
        "www1.www1.web-platform.test"
        "op18.not-web-platform.test"
        "op22.web-platform.test"
        "xn--lve-6lad.xn--lve-6lad.not-web-platform.test"
        "op63.not-web-platform.test"
        "op28.not-web-platform.test"
        "op65.web-platform.test"
        "www.www1.not-web-platform.test"
        "www1.xn--lve-6lad.web-platform.test"
        "op43.not-web-platform.test"
        "op66.not-web-platform.test"
        "www2.www.web-platform.test"
        "op96.web-platform.test"
        "op91.not-web-platform.test"
        "www.xn--lve-6lad.web-platform.test"
        "op1.web-platform.test"
        "op74.not-web-platform.test"
        "op87.web-platform.test"
        "op59.not-web-platform.test"
        "op19.web-platform.test"
        "xn--n8j6ds53lwwkrqhv28a.www1.not-web-platform.test"
        "op9.not-web-platform.test"
        "op88.not-web-platform.test"
        "op53.web-platform.test"
        "www2.xn--lve-6lad.not-web-platform.test"
        "op87.not-web-platform.test"
        "op30.web-platform.test"
        "op10.not-web-platform.test"
        "op48.web-platform.test"
        "op16.not-web-platform.test"
        "op34.web-platform.test"
        "op1.not-web-platform.test"
        "www.web-platform.test"
        "op5.web-platform.test"
        "www1.xn--lve-6lad.not-web-platform.test"
        "xn--lve-6lad.www2.not-web-platform.test"
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

  services.samba = {
    enable = true;
    extraConfig = ''
      syslog = 3
      map to guest = Bad User
      guest account = nobody
    '';
    shares = {
      scanner = {
        path = "/home/scanner";
        "guest ok" = "yes";
        "read only" = "no";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
    };
  };

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
  users.extraGroups.wireshark.members = [ "delan" ];

  security.sudo.extraConfig = ''
    delan ALL = NOPASSWD: /run/current-system/sw/bin/zfs
  '';

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  virtualisation.virtualbox.host = {
    # enable = true;
    # enableExtensionPack = true;
  };
  users.extraGroups.vboxusers.members = [ "delan" ];

  services.flatpak.enable = true;
  xdg.portal.enable = true;
}
