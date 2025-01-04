# manual setup after initial switch:
# - sudo smbpasswd -a scanner
# - sed s/hunter2/.../ iscsi-etc-target-saveconfig.json | sudo tee /etc/target/saveconfig.json
# - cd /config/nix/nixos/venus; sudo tailscale up; sudo tailscale cert venus.tailcdc44b.ts.net
{ config, lib, options, modulesPath, pkgs, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "99D8468B";
    hostName = "venus";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/cuffs2x2";
    bootDevice = "/dev/disk/by-uuid/3A36-D233";
    # TODO: use swap <https://chrisdown.name/2018/01/02/in-defence-of-swap.html>
    # <https://fxtwitter.com/dazabani/status/785108261078913024>
    swapDevice = null;
    separateNix = false;
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    services = {
      samba = true;
      qbittorrent = true;
    };
  };

  # hardware-configuration.nix
  # merged below # boot.kernelModules = [ "kvm-intel" ];
  # merged below # boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "vfio_pci" "usbhid" "sd_mod" ];
  nix.settings.max-jobs = lib.mkDefault 8;

  boot = {
    initrd = {
      availableKernelModules = [
        # for luks local/remote unlock
        "hid-microsoft" "igb"

        "mpt3sas"

        # hardware-configuration.nix
        "xhci_pci" "ehci_pci" "ahci" "vfio_pci" "usbhid" "sd_mod"
      ];

      verbose = true;
      network.enable = true;
      network.postCommands = ''
        for nic in eno1 eno2 eno3 eno4; do
          break
          ip link set $nic up
          if [ "$(cat /sys/class/net/$nic/carrier)" -eq 1 ]; then
            >&2 echo $nic is connected
            ip addr add 172.19.42.2/24 dev $nic
            ip route add default via 172.19.42.1 dev $nic
            break
          else
            >&2 echo $nic is not connected
          fi
        done
      '';
      network.ssh = {
        enable = true;
        port = 22;
        authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICBvkS7z2RAWzqRByRsHHB8PoCjXrnyHtjpdTxmOdcom delan@azabani.com/2016-07-18/Ed25519" ];
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      };
      luks.devices = {
        ocean0x0 = { device = "/dev/disk/by-partlabel/ocean0x0"; };
        ocean0x1 = { device = "/dev/disk/by-partlabel/ocean0x1"; };
        ocean1x0 = { device = "/dev/disk/by-partlabel/ocean1x0"; };
        ocean1x1 = { device = "/dev/disk/by-partlabel/ocean1x1"; };
        ocean2x0 = { device = "/dev/disk/by-partlabel/ocean2x0"; };
        ocean2x2 = { device = "/dev/disk/by-partlabel/ocean2x2"; };
        ocean3x0 = { device = "/dev/disk/by-partlabel/ocean3x0"; };
        ocean3x1 = { device = "/dev/disk/by-partlabel/ocean3x1"; };
        ocean4x0 = { device = "/dev/disk/by-partlabel/ocean4x0"; };
        ocean4x2 = { device = "/dev/disk/by-partlabel/ocean4x2"; };
        ocean5x0 = { device = "/dev/disk/by-partlabel/ocean5x0"; };
        ocean5x1 = { device = "/dev/disk/by-partlabel/ocean5x1"; };
        oceanSx0 = { device = "/dev/disk/by-partlabel/oceanSx0"; };
        oceanSx1 = { device = "/dev/disk/by-partlabel/oceanSx1"; };
      };
    };

    kernelModules = [
      "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"

      # hardware-configuration.nix
      "kvm-intel"
    ];

    kernelParams = [
      "intel_iommu=on" # "vfio_pci.ids=1000:0072"
      "default_hugepagesz=1G" "hugepagesz=1G" # "hugepages=20"
      ####### "isolcpus=0,4,1,5" "nohz_full=0,4,1,5" "rcu_nocbs=0,4,1,5"

      # for GPU-Z https://www.reddit.com/r/VFIO/comments/ahg1ta
      "kvm.ignore_msrs=1"
    ];

    extraModprobeConfig = ''
      # for VMware https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/
      options kvm_intel nested=1

      # FIXME testing for openzfs/zfs#15646
      options zfs zfs_vdev_disk_classic=0
      # options zfs zfs_vdev_disk_debug_bio_fill=1  # set this at runtime
      # options zfs zfs_abd_page_iter_disable_compound=1  # set this at runtime
    '';

    # https://sholland.org/2016/howto-pass-usb-ports-to-kvm/
    # (0x3ff7 /* webcam */ & 0x3fef /* mouse */ & 0x3fdf /* keyboard */ & 0x3eff /* dac */ /* & 0x3bff /* bmc */).toString(16)
    # ~(0x0008 /* webcam */ | 0x0010 /* mouse */ | 0x0020 /* keyboard */ | 0x0100 /* dac */ /* | 0x0400 /* bmc */).toString(16)
    # initrd.extraUtilsCommands = "copy_bin_and_libs ${pkgs.pciutils}/bin/setpci";
    # initrd.preDeviceCommands = "setpci -s0:14.0 0xd0.W=0x3ec7";
    # postBootCommands = "/run/current-system/sw/bin/setpci -s0:14.0 0xd0.W=0x3ec7";

    # FIXME workaround for openzfs/zfs#15646
    zfs.extraPools = [ "ocean" ];
    zfs.devNodes = "/dev/mapper"; # prettier zpool list/status
    postBootCommands = ''
      (
        exit
        set -eu -- ocean0x0 ocean0x1 ocean1x0 ocean1x1 ocean2x0 ocean2x2 ocean3x0 ocean3x1 ocean4x0 ocean4x2 ocean5x0 ocean5x1 oceanSx0 oceanSx1 ocean.arc
        i=100
        for j; do
          shift
          mknod -m 660 /dev/loop$i b 7 $i
          tries=3
          while ! [ -e /dev/loop$i ] || ! losetup --show /dev/loop$i /dev/mapper/$j; do
            test $tries -gt 0
            >&2 echo "waiting for /dev/loop$i to become ready"
            sleep 1
            tries=$((tries-1))
          done
          set -- "$@" -d /dev/loop$i
          i=$((i+1))
        done
        # /!\ import manually for now
        # ${config.boot.zfs.package}/bin/zpool import "$@" ocean
      )
    '';
  };

  services.znapzend = {
    enable = true;
    pure = true;
    zetup = {
      "ocean" = {
        timestampFormat = "znapzend-%Y-%m-%dT%H:%M:%SZ";
        plan = "1h=>10min,1d=>1h,1m=>1d,1y=>1m";
        recursive = true;
      };
      "ocean/dump/aria" = {
        enable = false;
        plan = "";  # required by nixos
        recursive = true;
      };
    };
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
    virt-manager

    atool
    bc
    clang
    gcc
    colordiff
    file
    git
    gnumake
    idle3tools
    iftop
    jq
    lazygit
    lazydocker
    lsiutil
    lsof
    ncdu
    neofetch
    nmap
    ntfs3g
    openiscsi
    ripgrep
    sg3_utils
    smartmontools
    steam-run
    targetcli
    unzip
  ];

  services.cron = {
    enable = true;
    systemCronJobs = ["0 21 * * * root ~delan/bin/sync.sh"];
  };

  # for sshfs -o allow_other,default_permissions,idmap=user
  programs.fuse.userAllowOther = true;

  networking.firewall.allowedTCPPorts = [
    80 443 8443 # nginx
    8123 # home-assistant
    7474 # autobrr
    1313 # zfs send
    111 2049 # nfs
    8000 # python
    3260 # iscsi
    25565 # minecraft (gtnh)
    25566 # minecraft (monifactory)
  ];
  networking.firewall.allowedUDPPorts = [
    80 443 8443 # nginx
    111 2049 # nfs
  ];

  # allows you to authenticate sudo using your ssh private key
  # use `ssh venus -A` (and maybe run `ssh-add` beforehand if things break)
  # to get this to work
  security.pam.enableSSHAgentAuth = true;
  security.pam.services.sudo.sshAgentAuth = true;

  security.acme = {
    acceptTerms = true;
    certs."venus.daz.cat" = {
      email = "delan@azabani.com";
      credentialsFile = "/etc/nixos/venus/acme-env.txt";
      dnsProvider = "exec";
      extraDomainNames = [];
    };
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "64M";
    virtualHosts = let
      proxy = {
        extraConfig = ''
          # https://github.com/curl/curl/issues/674
          # https://trac.nginx.org/nginx/ticket/915
          proxy_hide_header Upgrade;
        '';
      };
      sslAcme = {
        useACMEHost = "venus.daz.cat";
      };
      sslRelax = {
        addSSL = true;
      };
      sslForce = {
        forceSSL = true;
      };
      syncloungeOnly = {
        "/synclounge/" = proxy // {
          proxyPass = "http://127.0.0.1:20080/";
          extraConfig = ''
            # https://github.com/synclounge/synclounge/blob/714ac01ec334c41a707c445bee32619e615550cf/README.md#subfolder-domaincomsomefolder
            proxy_http_version 1.1;
            proxy_socket_keepalive on;
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $server_name;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
            proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
            proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;
          '';
        };
      };
      venus = syncloungeOnly // {
        "/qbittorrent/" = proxy // {
          proxyPass = "http://127.0.0.1:20000/";
        };
        "/sonarr/" = proxy // {
          proxyPass = "http://127.0.0.1:20010";
        };
        "/radarr/" = proxy // {
          proxyPass = "http://127.0.0.1:20020";
        };
        "/prowlarr/" = proxy // {
          proxyPass = "http://127.0.0.1:20040";
        };
        "/bazarr/" = proxy // {
          proxyPass = "http://127.0.0.1:20050";
        };
      };
    in {
      "venus.daz.cat" = sslForce // sslAcme // {
        locations = venus;
      };
      "venus.tailcdc44b.ts.net:8443" = {
        listen = [{
          addr = "venus.tailcdc44b.ts.net";
          port = 8443;
          ssl = true;
        }];
        sslCertificate = ./venus.tailcdc44b.ts.net.crt;
        sslCertificateKey = ./venus.tailcdc44b.ts.net.key;
        onlySSL = true;
        locations = syncloungeOnly;
      };
    };
  };
  services.target.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      # 172.19.42.6 = tol
      /ocean 172.19.42.6(ro,all_squash)
      /ocean/active 172.19.42.6(ro,all_squash)

      /ocean jupiter.tailcdc44b.ts.net.(rw)
      /ocean/active jupiter.tailcdc44b.ts.net.(rw)
      /ocean/private jupiter.tailcdc44b.ts.net.(rw)
      /ocean/public jupiter.tailcdc44b.ts.net.(rw)
    '';
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  programs.fish.enable = true;
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
      users.nginx.extraGroups = [ "acme" ];
      users.aria = {
        isNormalUser = true;
        uid = 1001;
        shell = pkgs.zsh;
        extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
      };
      users.the6p4c = {
        isNormalUser = true;  # HACK: not true
        uid = 1002;
        shell = pkgs.bash;
        extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
      };
      users.lucatiel = {
        isNormalUser = true;
        uid = 1003;
        shell = pkgs.bash;
        extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
      };
      users.ruby = {
        isNormalUser = true;
        uid = 1004;
        shell = pkgs.fish;
        extraGroups = [ "systemd-journal" "wheel" "networkmanager" "libvirtd" "docker" ];
        openssh.authorizedKeys.keys = ["sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBveMRzoY0e0F2c2f9N/gZ7zFBIXJGhNPSAGI5/XTaBMAAAABHNzaDo="];
      };
      users.hannah = {
        isNormalUser = true;
        uid = 13000;
        shell = pkgs.zsh;
        group = "hannah";
        extraGroups = [ "systemd-journal" ];
      };
      groups.hannah = {
        gid = 13000;
      };
    }
    [
      (system { name = "sonarr"; id = 2001; })
      (system { name = "radarr"; id = 2002; })
      (system { name = "recyclarr"; id = 2003; })
      (system { name = "prowlarr"; id = 2004; })
      (system { name = "bazarr"; id = 2005; })
      (system { name = "flaresolverr"; id = 2006; })
      (system { name = "scanner"; id = 2007; })
      (system { name = "synclounge"; id = 2008; })
      (system { name = "gtnh"; id = 2009; })
    ];
}
