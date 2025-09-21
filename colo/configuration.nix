# manual setup after initial switch:
# - provide ./home_colo.ovpn, root:root 600
# - tailscale up
# - chown -R nginx:nginx ./nginx
# - chown -R kate:users ./kate
# - provide /config/kate/dariox.club.conf, kate:users 644
# - provide /config/kate/xenia-dashboard.conf, kate:users 644
# - sudo mkdir -p /var/www/memories/pebble
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories/pebble
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories
# - provide /var/www/memories/pebble/**
# - sudo mkdir -p /var/cache/nginx/fedi-media-proxy.shuppy.org
# - sudo chown nginx:nginx /var/cache/nginx/fedi-media-proxy.shuppy.org
{ config, lib, options, modulesPath, pkgs, specialArgs }: with lib; {
  imports = [ ../lib ];

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

      # docker breaks ipv6 neighbor solicitation to libvirt guests on this server.
      # it broke when we first tried to run cohost-embed on the host, and it broke
      # again when we upgraded to nixos 24.05, even with that container stopped.
      # i have no idea why.
      docker = false;
    };

    services = {
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
    firewall = {
      # logRefusedUnicastsOnly = false;
      # logRefusedPackets = true;

      allowedTCPPorts = [
        # dns
        53

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
      forwardPorts = [
        # port forward dns to opacus
        {
          sourcePort = 53;
          proto = "udp";
          destination = "172.19.130.245:53";
        }
        {
          sourcePort = 53;
          proto = "tcp";
          destination = "172.19.130.245:53";
        }
      ];
    };
  };

  security = {
    acme.acceptTerms = true;
    acme.certs."colo.daz.cat" = {
      email = "delan@azabani.com";
      # copyPathToStore gives the file its own store path, which gets copied to the machine.
      # without copyPathToStore, the path refers into the flake, which does not get copied
      # (it only exists in the deploying machine’s store).
      credentialsFile = pkgs.copyPathToStore ./acme-env.daz.txt;
      dnsProvider = "exec";
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
      credentialsFile = pkgs.copyPathToStore ./acme-env.shuppy.txt;
      dnsProvider = "exec";
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
        opacus = {
          locations."/" = proxy // {
            proxyPass = "http://172.19.130.245";
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
        "103.108.231.122" = stratus // sslRelax;
        "2404:f780:8:3006:8f04::1500" = stratus // sslRelax;
        "opacus.daz.cat" = opacus // sslForce;
        "stratus.daz.cat" = stratus // sslForce;
        "bucket.daz.cat" = opacus // sslRelax;
        "memories.daz.cat" = {
          locations."/" = {
            root = "/var/www/memories";
            extraConfig = ''
              include /run/secrets/memories-external-vhosts.conf;
            '';
          };
        } // sslForce;
        "charming.daz.cat" = opacus // sslForce;
        "funny.computer.daz.cat" = opacus // sslRelax;
        "go.daz.cat" = opacus // sslForce;
        "xn--blhaj-nra.daz.cat" = opacus // sslForce;
        "test.daz.cat" = jupiter 8000 // sslForce;
        "azabani.com" = opacus // sslForce;
        "www.azabani.com" = opacus // sslForce;
        "ar1as.space" = opacus // sslForce;
        ".sixte.st" = stratus // sslRelax;
        "isbtrfsstableyet.com" = opacus;
        "kierang.ee.nroach44.id.au" = opacus // sslRelax;
        "shuppy.org" = sslShuppy // {
          locations."/" = {
            root = "/var/www/shuppy.org";
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

    (writeScriptBin "acme-dns.daz.sh" (readFile ./acme-dns.daz.sh))
    (writeScriptBin "acme-dns.shuppy.sh" (readFile ./acme-dns.shuppy.sh))
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
