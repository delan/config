{ config, lib, options, modulesPath, pkgs, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "8FF7BF00";
    hostName = "tol";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/tol.cuffs";
    bootDevice = "/dev/disk/by-partlabel/tol.esp";
    separateNix = true;
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    services = {};
  };

  swapDevices = [ { device = "/dev/disk/by-partlabel/tol.swap"; } ];
  nix.settings.max-jobs = lib.mkDefault 4;

  boot = {
    initrd = {
      availableKernelModules = [
        # for luks local/remote unlock
        "hid-microsoft" "igb"

        # hardware-configuration.nix
        "xhci_pci" "ehci_pci" "ahci" "vfio_pci" "usbhid" "sd_mod"
      ];

      verbose = true;
      # network.enable = true;
      # network.postCommands = ''
      #   for nic in eno1 eno2 eno3 eno4; do
      #     break
      #     ip link set $nic up
      #     if [ "$(cat /sys/class/net/$nic/carrier)" -eq 1 ]; then
      #       >&2 echo $nic is connected
      #       ip addr add 172.19.42.2/24 dev $nic
      #       ip route add default via 172.19.42.1 dev $nic
      #       break
      #     else
      #       >&2 echo $nic is not connected
      #     fi
      #   done
      # '';
      # network.ssh = {
      #   enable = true;
      #   port = 22;
      #   authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICBvkS7z2RAWzqRByRsHHB8PoCjXrnyHtjpdTxmOdcom delan@azabani.com/2016-07-18/Ed25519" ];
      #   hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      # };
    };

    kernelModules = [
      "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"

      # hardware-configuration.nix
      "kvm-intel"
    ];

    kernelParams = [
      "intel_iommu=on"

      # for GPU-Z https://www.reddit.com/r/VFIO/comments/ahg1ta
      "kvm.ignore_msrs=1"
    ];

    # for VMware https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
    extraModprobeConfig = "options kvm_intel nested=1";
  };

  fileSystems."/ocean" = {
    device = "venus.home.daz.cat.:/ocean";
    fsType = "nfs";
    options = [ "noauto" "ro" "soft" "bg" ];
  };

  fileSystems."/ocean/active" = {
    device = "venus.home.daz.cat.:/ocean/active";
    fsType = "nfs";
    options = [ "noauto" "ro" "soft" "bg" ];
  };

  environment.systemPackages = with pkgs; [
    tmux htop pv vim iperf3 neovim

    # nix-locate(1)
    nix-index

    # hardware stuff
    pciutils usbutils ipmitool lm_sensors

    # virt-clone(1)
    virt-manager

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
    lazydocker
    lsiutil
    lsof
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
    32400 # plex
  ];
  networking.firewall.allowedUDPPorts = [
    32400 # plex
  ];

  users = let
    system = { name, id }: {
      users."${name}" = {
        uid = id;
        group = name;
        isSystemUser = true;
      };
      groups."${name}" = {
        gid = id;
      };
    };
  in builtins.foldl' lib.recursiveUpdate
    {
      users.aria = {
        isNormalUser = true;
        uid = 1001;
        shell = pkgs.zsh;
        extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
      };
    }
    [
      (system { name = "plex"; id = 2101; })
    ];
}
