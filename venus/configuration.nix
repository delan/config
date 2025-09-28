# manual setup after initial switch:
# - sudo smbpasswd -a scanner
# - sudo smbpasswd -a paperless
# - sed s/hunter2/.../ iscsi-etc-target-saveconfig.json | sudo tee /etc/target/saveconfig.json
# - cd /config/nix/nixos/venus; sudo tailscale up; sudo tailscale cert venus.tailcdc44b.ts.net
# - sudo podman network create arr
# - sudo podman network create paperless
{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  imports = [ ../lib ./akkoma.nix ];

  internal = {
    hostId = "99D8468B";
    hostName = "venus";
    domain = "daz.cat";
    oldCuffsNames = true;
    unstableWorkstationsCompat = false;
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

    tailscale = true;

    ids = {
      "qbittorrent" = { id = 2000; port = 20000; };
      "sonarr" = { id = 2001; port = 20010; };
      "radarr" = { id = 2002; port = 20020; };
      "recyclarr" = { id = 2003; };
      "prowlarr" = { id = 2004; port = 20040; };
      "bazarr" = { id = 2005; port = 20050; };
      "flaresolverr" = { id = 2006; port = 20060; };
      "scanner" = { id = 2007; };
      "synclounge" = { id = 2008; port = 20080; };
      "minecraft" = { id = 2009; };
      "homepage" = { id = 2010; port = 20100; };
      "decluttarr" = { id = 2011; };
      "paperless" = { id = 2012; port = 20120; };
      "akkoma" = { id = 2013; port = 20130; };
      "postgres" = {
        id = 2014;
        # override the deprecated static uid
        # https://github.com/NixOS/nixpkgs/blob/f9ebe33a928b5d529c895202263a5ce46bdf12f7/nixos/modules/services/databases/postgresql.nix#L575-L584
        # https://github.com/NixOS/nixpkgs/blob/f9ebe33a928b5d529c895202263a5ce46bdf12f7/nixos/modules/misc/ids.nix#L110
        force = true;
      };
    };
  };

  sops.secrets.tailscale-ssl-cert = {
    sopsFile = ../secrets/venus/tailscale-ssl.yaml;
    name = "venus.tailcdc44b.ts.net.crt";
    owner = "nginx";
  };
  sops.secrets.tailscale-ssl-key = {
    sopsFile = ../secrets/venus/tailscale-ssl.yaml;
    name = "venus.tailcdc44b.ts.net.key";
    owner = "nginx";
  };
  sops.secrets.radarr-api-key = {
    sopsFile = ../secrets/venus/containers.yaml;
  };
  sops.secrets.sonarr-api-key = {
    sopsFile = ../secrets/venus/containers.yaml;
  };

  specialisation.no-storage.configuration = {
    boot.initrd.luks.devices = mkForce {
      cuffs = {
        device = config.internal.luksDevice;
      };
    };
    boot.zfs.extraPools = mkForce [];
    services.nfs.server.enable = mkForce false;
    services.samba.enable = mkForce false;
    virtualisation.oci-containers.containers = mkForce (import ./containers.nix {
      inherit config;
      autoStart = false;
    });
    internal.services.qbittorrent = mkForce false;
    services.akkoma.enable = mkForce false;
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
        ocean5x2 = { device = "/dev/disk/by-partlabel/ocean5x2"; };
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

      # openzfs/zfs#15646
      options zfs zfs_vdev_disk_classic=0
    '';

    # https://sholland.org/2016/howto-pass-usb-ports-to-kvm/
    # (0x3ff7 /* webcam */ & 0x3fef /* mouse */ & 0x3fdf /* keyboard */ & 0x3eff /* dac */ /* & 0x3bff /* bmc */).toString(16)
    # ~(0x0008 /* webcam */ | 0x0010 /* mouse */ | 0x0020 /* keyboard */ | 0x0100 /* dac */ /* | 0x0400 /* bmc */).toString(16)
    # initrd.extraUtilsCommands = "copy_bin_and_libs ${pkgs.pciutils}/bin/setpci";
    # initrd.preDeviceCommands = "setpci -s0:14.0 0xd0.W=0x3ec7";
    # postBootCommands = "/run/current-system/sw/bin/setpci -s0:14.0 0xd0.W=0x3ec7";

    zfs.extraPools = [ "ocean" ];
    zfs.devNodes = "/dev/mapper"; # prettier zpool list/status
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

    (writeScriptBin "acme-dns.daz.sh" (readFile ./acme-dns.daz.sh))
    (writeScriptBin "import-ocean.sh" (readFile ./import-ocean.sh))
    (writeScriptBin "export-ocean.sh" (readFile ./export-ocean.sh))
    (writeScriptBin "fix-ocean-perms.sh" (readFile ./fix-ocean-perms.sh))
    (writeScriptBin "ocean-dfree.sh" (readFile ./ocean-dfree.sh))
  ];

  services.cron = {
    enable = true;
    systemCronJobs = ["0 21 * * * root sync.sh"];
  };

  networking.firewall.allowedTCPPorts = [
    80 443 # nginx
    8123 # home-assistant
    7474 # autobrr
    1313 # zfs send
    111 2049 # nfs
    8000 # python
    3260 # iscsi
    5201 5202 # iperf3
    25565 # minecraft (gtnh)
    25566 # minecraft (monifactory)
  ];
  networking.firewall.allowedUDPPorts = [
    80 443 # nginx
    111 2049 # nfs
    5201 5202 # iperf3
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
      # copyPathToStore gives the file its own store path, which gets copied to the machine.
      # without copyPathToStore, the path refers into the flake, which does not get copied
      # (it only exists in the deploying machine’s store).
      credentialsFile = pkgs.copyPathToStore ./acme-env.daz.txt;
      dnsProvider = "exec";
      extraDomainNames = [
        "homepage.venus.daz.cat"
      ];
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
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.synclounge.port}/";
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
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.qbittorrent.port}/";
        };
        "/sonarr/" = proxy // {
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.sonarr.port}";
        };
        "/radarr/" = proxy // {
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.radarr.port}";
        };
        "/prowlarr/" = proxy // {
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.prowlarr.port}";
        };
        "/bazarr/" = proxy // {
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.bazarr.port}";
        };
        "/paperless/" = proxy // {
          proxyPass = "http://127.0.0.1:${toString config.internal.ids.paperless.port}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    in {
      "venus.daz.cat" = sslForce // sslAcme // {
        locations = venus;
      };
      "venus.tailcdc44b.ts.net" = sslForce // sslAcme // {
        locations = venus;
      };
    };
  };
  systemd.services.nginx.wants = [ "tailscaled.service" ];
  systemd.services.nginx.after = [ "tailscaled.service" ];

  services.target.enable = true;

  services.nfs.server = {
    enable = true;
    exports = ''
      # 172.19.42.6 = tol
      /ocean 172.19.42.6(ro,all_squash)
      /ocean/active 172.19.42.6(ro,all_squash)

      # jupiter.tailcdc44b.ts.net. jupiter.home.daz.cat. frappetop.tailcdc44b.ts.net.
      # if nfs-mountd.service starts before tailscale is up, names will fail to
      # resolve here, breaking the exports. mount -v will fail with “mount(2):
      # Permission denied” and “access denied by server while mounting”.
      # <https://github.com/tailscale/tailscale/issues/11504>
      /ocean -rw 100.64.202.115 172.19.42.3 100.119.186.118
      /ocean/active -rw 100.64.202.115 172.19.42.3 100.119.186.118
      /ocean/private -rw 100.64.202.115 172.19.42.3 100.119.186.118
      /ocean/public -rw 100.64.202.115 172.19.42.3 100.119.186.118
    '';
  };

  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb-7_0;
  };

  programs.fish.enable = true;
  users = {
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
  };

  virtualisation.oci-containers.containers = import ./containers.nix {
    inherit config;
  };
}
