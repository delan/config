# manual setup after initial switch:
# - provide ./home_colo.ovpn, root:root 600
# - tailscale up
# - provide /config/nginx/charming.daz.cat.conf, delan:users 644
# - provide /config/nginx/go.daz.cat.conf, delan:users 644
# - provide /config/kate/dariox.club.conf, kate:users 644
# - provide /config/kate/xenia-dashboard.conf, kate:users 644
# - sudo mkdir -p /var/www/memories/pebble
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories/pebble
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories
# - provide /var/www/memories/pebble/**
# - sudo mkdir -p /var/cache/nginx/fedi-media-proxy.shuppy.org
# - sudo chown nginx:nginx /var/cache/nginx/fedi-media-proxy.shuppy.org
{ config, lib, options, modulesPath, pkgs, specialArgs }: with lib; {
  imports = [ ../lib ./dns.nix ./falling-sky ];

  internal = {
    hostId = "99D8468B";
    hostName = "colo";
    domain = "daz.cat";
    oldCuffsNames = true;
    unstableWorkstationsCompat = false;
    luksDevice = "/dev/disk/by-uuid/a8b6dd52-8f9f-42f8-badc-53b43aa9a4df";
    bootDevice = "/dev/disk/by-uuid/0CA9-2BEC";
    swapDevice = null;
    separateNix = true;
    initialUser = "delan";

    virtualisation = {
      libvirt = true;
      docker = true;
    };

    tailscale = true;
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1cc6aab2-3044-47c9-a478-e2ff04c0f480"; }
  ];

  sops.secrets = {
    memories-external-vhosts = {
      sopsFile = ../secrets/colo/memories.yaml;
      name = "memories-external-vhosts.conf";
      owner = "nginx";
    };
    memories-internal-vhosts = {
      sopsFile = ../secrets/colo/memories.yaml;
      name = "memories-internal-vhosts.conf";
      owner = "nginx";
    };
    memories-htpasswd-f = {
      sopsFile = ../secrets/colo/memories.yaml;
      owner = "nginx";
    };
    memories-htpasswd-p = {
      sopsFile = ../secrets/colo/memories.yaml;
      owner = "nginx";
    };
  };

  boot = {
    kernelModules = [ "vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1" ];

    kernelParams = [
      "intel_iommu=on" # "vfio_pci.ids=1000:0072,10de:13c2,10de:0fbb"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
    ];

    initrd = {
      availableKernelModules = [ "igb" ];
      verbose = true;
      network.enable = true;
      network.postCommands = ''
        for nic in eno1 eno2 eno3 eno4; do
          if [ "$(cat /sys/class/net/$nic/carrier)" -eq 1 ]; then
            >&2 echo $nic is connected
            ip addr add 103.108.231.122/29 dev $nic
            ip route add default via 103.108.231.121 dev $nic
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
        cuffs0x0 = {
          device = "/dev/disk/by-partlabel/colo.cuffs0x0";
        };
        cuffs0x1 = {
          device = "/dev/disk/by-partlabel/colo.cuffs0x1";
        };
      };
    };
  };

  networking = {
    networkmanager.ensureProfiles.profiles = {
      bridge13 = {
        bridge = {
          mac-address = "CE:CC:FF:EE:46:8B";
          stp = "false";
        };
        connection = {
          id = "bridge13";
          interface-name = "bridge13";
          type = "bridge";
          uuid = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
        };
        ethernet = { };
        ipv4 = {
          address1 = "103.108.231.122/29,103.108.231.121";
          dns = "8.8.8.8;8.8.4.4;";
          method = "manual";
        };
        ipv6 = {
          addr-gen-mode = "eui64";
          ip6-privacy = "2";
          method = "auto";
        };
        proxy = { };
      };
      child-eno1 = {
        bridge-port = { };
        connection = {
          controller = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          id = "child-eno1";
          interface-name = "eno1";
          master = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          port-type = "bridge";
          slave-type = "bridge";
          type = "ethernet";
          uuid = "e4929ddd-0e2f-4b4a-9c5c-2b710b569d5b";
        };
        ethernet = { };
      };
      child-eno2 = {
        bridge-port = { };
        connection = {
          controller = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          id = "child-eno2";
          interface-name = "eno2";
          master = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          port-type = "bridge";
          slave-type = "bridge";
          type = "ethernet";
          uuid = "d4a14459-174b-453f-8667-4cdcef09289a";
        };
        ethernet = { };
      };
      child-eno3 = {
        bridge-port = { };
        connection = {
          controller = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          id = "child-eno3";
          interface-name = "eno3";
          master = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          port-type = "bridge";
          slave-type = "bridge";
          type = "ethernet";
          uuid = "5adb29f5-7736-4803-a392-84a94a55800e";
        };
        ethernet = { };
      };
      child-eno4 = {
        bridge-port = { };
        connection = {
          controller = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          id = "child-eno4";
          interface-name = "eno4";
          master = "1e71c0c7-6a9d-4624-bec8-9d23c562fda5";
          port-type = "bridge";
          slave-type = "bridge";
          type = "ethernet";
          uuid = "7282c7b1-d470-40a2-9a0b-0175c80e1da9";
        };
        ethernet = { };
      };
    };
    firewall = {
      # logRefusedUnicastsOnly = false;
      # logRefusedPackets = true;

      allowedTCPPorts = [
        # dns
        53

        # badapple
        5300

        # nginx
        80 443

        # kate
        27025
      ];
      allowedTCPPortRanges = [
        # libvirt migration
        { from = 49152; to = 49215; }
      ];
      allowedUDPPorts = [
        # dns
        53

        # badapple
        5300

        # dhcp
        67

        # nginx
        80 443

        # kate
        27025
      ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "virbr1" ];
      externalInterface = "bridge13";
      forwardPorts = [];
    };
  };

  security = {
    acme.acceptTerms = true;
    acme.certs."colo.daz.cat" = {
      email = "delan@azabani.com";
      # copyPathToStore gives the file its own store path, which gets copied to the machine.
      # without copyPathToStore, the path refers into the flake, which does not get copied
      # (it only exists in the deploying machine’s store).
      environmentFile = pkgs.copyPathToStore ./acme-env.daz.txt;
      dnsProvider = "rfc2136";
      postRun = ''
        /run/current-system/sw/bin/deploy-acme-to-opacus.sh
        /run/current-system/sw/bin/deploy-acme-to-stratus.sh
      '';
      extraDomainNames = [
        "test.daz.cat"
        "opacus.daz.cat"
        "stratus.daz.cat"
        "bucket.daz.cat"
        "memories.daz.cat"
        "charming.daz.cat"
        "twitter.daz.cat"
        "funny.computer.daz.cat"
        "go.daz.cat"
        "xn--blhaj-nra.daz.cat"
        "azabani.com"
        "www.azabani.com"
        "ar1as.space"
        "sixte.st"
        "*.sixte.st"
        "*.v6ns.sixte.st"
        "kierang.ee.nroach44.id.au"
      ];
    };
    acme.certs."shuppy.org" = {
      email = "letsencrypt.org@shuppy.org";
      # copyPathToStore gives the file its own store path, which gets copied to the machine.
      # without copyPathToStore, the path refers into the flake, which does not get copied
      # (it only exists in the deploying machine’s store).
      environmentFile = pkgs.copyPathToStore ./acme-env.shuppy.txt;
      dnsProvider = "rfc2136";
      postRun = ''
      '';
      extraDomainNames = [
        "meet.shuppy.org"
        "fedi.shuppy.org"
        "fedi-media.shuppy.org"
        "fedi-media-proxy.shuppy.org"
      ];
    };
  };
  users.users.nginx.extraGroups = [ "acme" ];

  services = {
    # colo network doesn’t have dhcp or dns, so we need our own dns server
    unbound = {
      enable = true;
      settings.forward-zone = [
        { name = "tailcdc44b.ts.net"; forward-addr = "100.100.100.100"; }
        # FIXME: try {64..127}.100.in-addr.arpa. to fix avahi rdns hang on ping
      ];
    };

    openvpn.servers.home = {
      config = "config /etc/nixos/colo/home_colo.ovpn";
      autoStart = false;
    };

    nginx = {
      enable = true;
      clientMaxBodySize = "34M";
      # logError = "stderr notice";
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedBrotliSettings = true;
      # avoid downtime if configuration has errors
      enableReload = true;

      # for akkoma
      # https://nixos.org/manual/nixos/stable/#modules-services-akkoma-media-proxy
      package = pkgs.nginxStable.override { withSlice = true; };
      commonHttpConfig = ''
        proxy_cache_path /var/cache/nginx/fedi-media-proxy.shuppy.org
          levels= keys_zone=fedi-media-proxy.shuppy.org:16m max_size=16g
          inactive=1y use_temp_path=off;
      '';

      appendHttpConfig = ''
        include /config/kate/dariox.club.conf;
        include /config/kate/xenia-dashboard.conf;
      '';
      virtualHosts = let
        proxy = {
          extraConfig = ''
              # https://github.com/curl/curl/issues/674
              # https://trac.nginx.org/nginx/ticket/915
              proxy_hide_header Upgrade;
          '';
        };
        ssl = {
          useACMEHost = "colo.daz.cat";
        };
        sslRelax = ssl // {
          addSSL = true;
        };
        sslForce = ssl // {
          forceSSL = true;
        };
        sslShuppy = {
          useACMEHost = "shuppy.org";
          forceSSL = true;
        };
        falling-sky = {
          locations."/" = proxy // {
            proxyPass = "http://127.0.0.1:1280";
          };
        };
        stratus = {
          locations."/" = proxy // {
            proxyPass = "http://172.19.130.235";
          };
        };
        jupiter = port: {
          locations."/" = proxy // {
            # jupiter.tailcdc44b.ts.net
            proxyPass = "http://100.64.202.115:${toString port}";
          };
        };
        venus = location: port: {
          locations."${location}" = proxy // {
            # venus.tailcdc44b.ts.net
            proxyPass = "http://100.95.253.127:${toString port}";
          };
        };
      in {
        "\"\"" = {
          locations."/disabled" = {
            return = "400";
          };
        };

        # falling-sky
        ".sixte.st" = falling-sky // sslRelax;
        "103.108.231.122" = falling-sky // sslRelax;
        "[2404:f780:8:3006::468b:1500]" = falling-sky // sslRelax;

        "stratus.daz.cat" = stratus // sslForce;
        "bucket.daz.cat" = sslRelax // {
          root = "/var/www/bucket.daz.cat";
          extraConfig = ''
            autoindex on;
          '';
          locations."= /" = {
            # trailing slash required
            alias = "/var/www/bucket.daz.cat/pub/";
            extraConfig = ''
              charset utf-8;
            '';
          };
          locations."/old/" = {
            return = "403";
          };
          locations."/private/" = {
            extraConfig = ''
              autoindex off;
            '';
          };
        };
        "memories.daz.cat" = {
          locations."/" = {
            root = "/var/www/memories";
            extraConfig = ''
              include /run/secrets/memories-external-vhosts.conf;
            '';
          };
        } // sslForce;
        "charming.daz.cat" = sslForce // {
          root = "/var/www/charming.daz.cat";
          extraConfig = ''
            include /config/nginx/charming.daz.cat.conf;
          '';
        };
        "twitter.daz.cat" = sslForce // {
          locations."/" = {
            root = "/var/www/twitter.daz.cat";
          };
        };
        "funny.computer.daz.cat" = sslRelax // {
          root = "/var/www/funny.computer.daz.cat/production";
        };
        "go.daz.cat" = sslForce // {
          extraConfig = ''
            include /config/nginx/go.daz.cat.conf;
          '';
        };
        "xn--blhaj-nra.daz.cat" = sslForce // {
          root = "/var/www/blåhaj.daz.cat";
        };
        "test.daz.cat" = jupiter 8000 // sslForce;
        "azabani.com" = sslForce // {
          locations."/" = {
            return = "301 https://www.azabani.com$request_uri";
          };
        };
        "www.azabani.com" = sslForce // {
          root = "/var/www/www.azabani.com/_production/_site";
          extraConfig = ''
            # Cache-Control: no-cache (max-age=0, must-revalidate)
            expires -1h;
          '';
          locations."/labs/charming/" = {
            extraConfig = ''
              # http 301
              rewrite ^/labs/charming/(.*)$ https://charming.daz.cat/$1;
            '';
          };
        };
        "ar1as.space" = sslForce // {
          root = "/var/www/ar1as.space";
        };
        "kierang.ee.nroach44.id.au" = sslForce // {
          root = "/var/www/kierang.ee";
          extraConfig = ''
            # required by shrine script
            autoindex on;
          '';
        };
        "shuppy.org" = sslShuppy // {
          locations."/" = {
            root = "/var/www/shuppy.org";
            extraConfig = ''
              # Cache-Control: no-cache (max-age=0, must-revalidate)
              expires -1h;
            '';
          };
          locations."= /.well-known/host-meta" = {
            return = "303 https://fedi.shuppy.org$request_uri";
          };
          locations."~ ^/https://?cohost[.]org/[^/]+/post/([0-9]+)" = {
            return = "302 https://shuppy.org/posts/$1.html";
          };
          locations."~ ^/https://?kolektiva[.]social/[^/]+/([0-9]+)" = {
            return = "302 https://shuppy.org/posts/$1.html";
          };
        };
        "meet.shuppy.org" = {
          enableACME = false;
          useACMEHost = "shuppy.org";
        };
        "fedi.shuppy.org" = sslShuppy // recursiveUpdate (venus "/" 20130) {
          locations."/" = {
            proxyWebsockets = true;
          };
        };
        "fedi-media.shuppy.org" = sslShuppy // recursiveUpdate (venus "/media/" 20130) {
          locations."/media/" = {
            proxyWebsockets = true;
          };
        };
        "fedi-media-proxy.shuppy.org" = sslShuppy // recursiveUpdate (venus "/proxy" 20130) {
          # https://nixos.org/manual/nixos/stable/#modules-services-akkoma-media-proxy
          locations."/proxy" = {
            extraConfig = ''
              proxy_cache fedi-media-proxy.shuppy.org;

              # Cache objects in slices of 1 MiB
              slice 1m;
              proxy_cache_key $host$uri$is_args$args$slice_range;
              proxy_set_header Range $slice_range;

              # Decouple proxy and upstream responses
              proxy_buffering on;
              proxy_cache_lock on;
              proxy_ignore_client_abort on;

              # Default cache times for various responses
              proxy_cache_valid 200 1y;
              proxy_cache_valid 206 301 304 1h;

              # Allow serving of stale items
              proxy_cache_use_stale error timeout invalid_header updating;
            '';
          };
        };
        "colo.tailcdc44b.ts.net" = {
          # TODO tailscale ssl
          listen = [{
            addr = "colo.tailcdc44b.ts.net";
          }];
          locations."/" = {
            root = "/var/www/memories";
            extraConfig = ''
              include /run/secrets/memories-internal-vhosts.conf;
            '';
          };
        };
      };
    };

    fail2ban = {
      enable = true;
      ignoreIP = [ "144.6.130.75" ];
    };
    jitsi-meet = {
      enable = true;
      hostName = "meet.shuppy.org";
      nginx.enable = true;
      # https://jitsi.github.io/handbook/docs/devops-guide/secure-domain
      secureDomain = {
        enable = true;
        authentication = "internal_hashed";
      };
      config = {
        audioQuality = {
          stereo = true;  # disable echo cancellation + noise suppression + AGC
          opusMaxAverageBitrate = 262144;  # default seems to be ~64kbit/s
        };
        p2p = {
          enabled = false;  # try to fix dropouts?
        };
      };
    };
    jitsi-videobridge = {
      openFirewall = true;
      nat = {
        # work around “No valid IP addresses available for harvesting.”
        # see also <https://github.com/jitsi/jitsi-meet/issues/14287>
        # <https://github.com/NixOS/nixpkgs/commit/61cf88212df30c8758a621086b9dafd06e7a551f>
        publicAddress = "103.108.231.122";
        localAddress = "103.108.231.122";
      };
      extraProperties = {
        "org.ice4j.ipv6.DISABLED" = "true";  # work around abb ipv6 dropouts
      };
    };

    falling-sky = {
      enable = true;
      domain = "sixte.st";
      ipv4-address = "103.108.231.122";
      ipv6-address = "2404:f780:8:3006::468b:1500";
      mtu1280-address = "2404:f780:8:3006::468b:1280";
      v6ns-soa-rname = "delan.azabani.com.";
      v6ns-acme-challenge-cname = "_acme-challenge.v6ns.sixte.st.acme.daz.cat.";
    };
  };

  environment.systemPackages = with pkgs; [
    tmux htop pv vim iperf3
    # openiscsi sg3_utils

    # nix-locate(1)
    nix-index

    # hardware stuff
    pciutils usbutils ipmitool lm_sensors

    # virt-clone(1)
    virt-manager

    ripgrep
    tcpdump

    kitty.terminfo  # for ruby

    (writeScriptBin "deploy-acme-to-opacus.sh" (readFile ./deploy-acme-to-opacus.sh))
    (writeScriptBin "deploy-acme-to-stratus.sh" (readFile ./deploy-acme-to-stratus.sh))
  ];

  services.cron = {
    enable = true;
    systemCronJobs = ["0 22 * * * root sync.sh"];
  };

  users.users.kate = {
    isNormalUser = true;
    uid = 1001;
    shell = pkgs.bash;
    extraGroups = [ "systemd-journal" ];
    initialHashedPassword = "$6$4NkWaZ7Un5r.CR2C$I22bgLqKU2DxlNye4jEicYmV06BFjcwe60q.cigaTQjeviYK0Aq7MITV09koexPSBPdvsibIxYo0rYwOJ7dlg0";  # hunter2
  };

  users.users.the6p4c = {
    isNormalUser = true;
    uid = 1002;
    shell = pkgs.bash;
    extraGroups = [ "systemd-journal" "wheel" ];
    initialHashedPassword = "$6$4NkWaZ7Un5r.CR2C$I22bgLqKU2DxlNye4jEicYmV06BFjcwe60q.cigaTQjeviYK0Aq7MITV09koexPSBPdvsibIxYo0rYwOJ7dlg0";  # hunter2
  };

  programs.fish.enable = true;
  users.users.ruby = {
    isNormalUser = true;
    uid = 1003;
    shell = pkgs.fish;
    extraGroups = [ "systemd-journal" "wheel" ];
    openssh.authorizedKeys.keys = ["sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBveMRzoY0e0F2c2f9N/gZ7zFBIXJGhNPSAGI5/XTaBMAAAABHNzaDo="];
  };

  services.udev.extraRules = ''
    # https://www.complete.org/managing-zfs-zvol-permissions-with-udev/
    KERNEL=="zd*" SUBSYSTEM=="block" ACTION=="add|change" PROGRAM="${pkgs.zfs.out}/lib/udev/zvol_id /dev/%k" RESULT=="cuffs/kate/*" OWNER="kate"
    KERNEL=="zd*" SUBSYSTEM=="block" ACTION=="add|change" PROGRAM="${pkgs.zfs.out}/lib/udev/zvol_id /dev/%k" RESULT=="cuffs/the6p4c/*" OWNER="the6p4c"
  '';
}
