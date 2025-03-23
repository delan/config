# manual setup after initial switch:
# - sudo smbpasswd -a scanner
# - sed s/hunter2/.../ iscsi-etc-target-saveconfig.json | sudo tee /etc/target/saveconfig.json
# - cd /config/nix/nixos/venus; sudo tailscale up; sudo tailscale cert venus.tailcdc44b.ts.net
# - sudo podman network create arr
# - sudo podman network create paperless
{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
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
        "/paperless/" = proxy // {
          proxyPass = "http://127.0.0.1:20090";
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
      "homepage.venus.daz.cat" = sslForce // sslAcme // {
        locations = {
          "/" = proxy // {
            proxyPass = "http://127.0.0.1:20070";
          };
        };
      };
      "venus.tailcdc44b.ts.net:8443" = {
        listen = [{
          addr = "venus.tailcdc44b.ts.net";
          port = 8443;
          ssl = true;
        }];
        # FIXME: why doesn’t config.sops work here?
        # sslCertificate = config.sops.secrets.tailscale-ssl-cert.path;
        # sslCertificateKey = config.sops.secrets.tailscale-ssl-key.path;
        sslCertificate = "/run/secrets/venus.tailcdc44b.ts.net.crt";
        sslCertificateKey = "/run/secrets/venus.tailcdc44b.ts.net.key";
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
      (system { name = "homepage"; id = 2010; })
      (system { name = "decluttarr"; id = 2011; })
      (system { name = "paperless"; id = 2012; })
    ];

  virtualisation.oci-containers.containers = {
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:2025.3.4";  
      environment = {
        TZ = "Australia/Perth";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/homeassistant:/config"
      ];
      extraOptions = [
        "--device=/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_a49962d47e45ed11a3dac68f0a86e0b4-if00-port0:/dev/ttyUSB0"  # zigbee controller
        "--network=host"  # network_mode: host
        # "--privileged"  # privileged: true (FIXME: do we really need this?)
      ];
    };
    sonarr = {
      image = "ghcr.io/hotio/sonarr:release-4.0.14.2939";
      ports = ["20010:8989"];
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        PUID = "2001";
        PGID = "2001";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/sonarr:/config"
        "/ocean/active:/ocean/active"
      ];
    };
    radarr = {
      image = "ghcr.io/hotio/radarr:release-5.20.2.9777";
      ports = ["20020:7878"];
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        PUID = "2002";
        PGID = "2002";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/radarr:/config"
        "/ocean/active:/ocean/active"
      ];
    };
    recyclarr = {
      image = "ghcr.io/recyclarr/recyclarr:7.4.1";
      user = "2003:2003";
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/recyclarr:/config"
      ];
    };
    prowlarr = {
      image = "ghcr.io/hotio/prowlarr:release-1.32.2.4987";
      ports = ["20040:9696"];
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        PUID = "2004";
        PGID = "2004";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/prowlarr:/config"
      ];
    };
    bazarr = {
      image = "ghcr.io/hotio/bazarr:release-1.5.1";
      ports = ["20050:6767"];
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        PUID = "2005";
        PGID = "2005";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/bazarr:/config"
        "/ocean/active:/ocean/active"
      ];
    };
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:v3.3.21";
      ports = ["20060:8191"];
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        LOG_LEVEL = "info";
      };
    };
    homepage = {
      image = "ghcr.io/gethomepage/homepage:v1.0.4";
      ports = ["20070:3000"];
      networks = ["arr"];
      volumes = [
        "/ocean/active/services/homepage:/app/config"
      ];
      environment = {
        HOMEPAGE_ALLOWED_HOSTS = "homepage.venus.daz.cat";
        PUID = "2010";
        PGID = "2010";
      };
    };
    decluttarr = {
      image = "ghcr.io/manimatter/decluttarr:v1.50.2";
      networks = ["arr"];
      environment = {
        TZ = "Australia/Perth";
        PUID = "2011";
        PGID = "2011";
        REMOVE_TIMER = "10";
        REMOVE_FAILED = "True";
        REMOVE_FAILED_IMPORTS = "True";
        REMOVE_METADATA_MISSING = "True";
        REMOVE_MISSING_FILES = "True";
        REMOVE_ORPHANS = "True";
        REMOVE_SLOW = "True";
        REMOVE_STALLED = "True";
        REMOVE_UNMONITORED = "True";
        RUN_PERIODIC_RESCANS = ''
        {
          "SONARR": {"MISSING": true, "CUTOFF_UNMET": true, "MAX_CONCURRENT_SCANS": 3, "MIN_DAYS_BEFORE_RESCAN": 7},
          "RADARR": {"MISSING": true, "CUTOFF_UNMET": true, "MAX_CONCURRENT_SCANS": 3, "MIN_DAYS_BEFORE_RESCAN": 7}
        }
        '';

        # Feature Settings
        PERMITTED_ATTEMPTS = "3";
        NO_STALLED_REMOVAL_QBIT_TAG = "Don't Kill";
        MIN_DOWNLOAD_SPEED = "100";
        FAILED_IMPORT_MESSAGE_PATTERNS = ''
        [
        "Not a Custom Format upgrade for existing",
        "Not an upgrade for existing"
        ]
        '';

        RADARR_URL = "http://radarr:7878/radarr";
        # RADARR_KEY = "";

        SONARR_URL = "http://sonarr:8989/sonarr";
        # SONARR_KEY = "";

        QBITTORRENT_URL = "http://172.19.42.2:20000";
      };
      environmentFiles = [config.sops.secrets.radarr-api-key.path config.sops.secrets.sonarr-api-key.path];
    };
    broker = {
      # for paperless-ngx
      image = "docker.io/library/redis:7.4.2";
      networks = ["paperless"];
      volumes = [
        "/ocean/active/services/paperless/redisdata:/data"
      ];
    };
    paperless = {
      # <https://github.com/paperless-ngx/paperless-ngx/blob/main/docker/compose/docker-compose.sqlite.yml>
      image = "ghcr.io/paperless-ngx/paperless-ngx:2.14.7";
      dependsOn = [ "broker" ];
      networks = ["paperless"];
      ports = ["20090:8000"];
      volumes = [
        "/ocean/active/services/paperless/data:/usr/src/paperless/data"
        "/ocean/active/services/paperless/media:/usr/src/paperless/media"
        "/ocean/active/services/paperless/export:/usr/src/paperless/export"
        "/ocean/active/services/paperless/inbox:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS = "redis://broker:6379";
        USERMAP_UID = "2012";
        USERMAP_GID = "2012";
        PAPERLESS_TIME_ZONE = "Australia/Perth";
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_URL = "https://venus.daz.cat";
        USE_X_FORWARD_HOST = "true";
        USE_X_FORWARD_PORT = "true";
        PAPERLESS_PROXY_SSL_HEADER = ''["HTTP_X_FORWARDED_PROTO", "https"]'';
        PAPERLESS_FORCE_SCRIPT_NAME = "/paperless";
        # PAPERLESS_STATIC_URL = "/paperless/static/";
      };
    };
    synclounge = {
      image = "synclounge/synclounge:5.2.35";
      ports = ["20080:8088"];
      user = "2008:2008";
      environment = {
        TZ = "Australia/Perth";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/ocean/active/services/bazarr:/config"
        "/ocean/active:/ocean/active"
      ];
    };
    gtnh = {
      image = "itzg/minecraft-server:java21-alpine";
      ports = ["25565:25565"];
      environment = {
        SETUP_ONLY = "false";

        TYPE = "CUSTOM";
        CUSTOM_SERVER = "/data/lwjgl3ify-forgePatches.jar";
        VERSION = "1.7.10";
        MOTD = "GTNH Shouse";
        DIFFICULTY = "2";
        LEVEL_TYPE = "RTG";
        SEED = "";
        JVM_OPTS = "-Dfml.readTimeout=180 @java9args.txt";

        INIT_MEMORY = "6G";
        MAX_MEMORY = "8G";
        ENABLE_AUTOPAUSE = "true";
        AUTOPAUSE_TIMEOUT_EST = "300";
        AUTOPAUSE_TIMEOUT_INIT = "60";
        VIEW_DISTANCE = "14";

        UID = "2009";
        GID = "2009";
        TZ = "Australia/Perth";
        EULA = "true";
        ONLINE_MODE = "true";
        ALLOW_FLIGHT = "true";
        ENFORCE_WHITELIST = "true";
        MAX_PLAYERS = "5";
        OVERRIDE_SERVER_PROPERTIES = "true";
        MAX_TICK_TIME = "-1";
        CREATE_CONSOLE_IN_PIPE = "true";
      };
      volumes = [
        "/ocean/active/services/gtnh:/data"
      ];
    };
    monifactory = {
      image = "itzg/minecraft-server:java21-alpine";
      ports = ["25566:25565"];
      environment = {
        EULA = "true";
        TYPE = "FORGE";
        VERSION = "1.20.1";
        FORGE_VERSION = "47.3.10";
        GENERIC_PACK = "https://github.com/ThePansmith/Monifactory/releases/download/0.9.10/Monifactory-Beta.0.9.10-server.zip";
        UID = "2009";
        GID = "2009";
        TZ = "Australia/Perth";
        MEMORY = "8G";
        USE_AIKAR_FLAGS = "true";
        WHITELIST = "ariashark,shuppyy";
        EXISTING_WHITELIST_FILE = "MERGE";
        OPS = "ariashark,shuppyy";
        EXISTING_OPS_FILE = "MERGE";
        MAX_PLAYERS = "5";
        ALLOW_FLIGHT = "true";
        DIFFICULTY = "peaceful";
        MOTD = "sharkuppy (ao!)";
      };
      volumes = [
        "/ocean/active/services/monifactory:/data"
      ];
    };
  };
}
