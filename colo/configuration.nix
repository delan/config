# manual setup after initial switch:
# - provide ./home_colo.ovpn, root:root 600
# - tailscale up
# - chown -R nginx:nginx ./nginx
# - chown -R kate:users ./kate
# - provide /config/kate/dariox.club.conf, kate:users 644
# - provide /config/kate/xenia-dashboard.conf, kate:users 644
# - sudo mkdir -p /var/www/memories/peb
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories/peb
# - sudo setfacl -n --set 'u::rwX,g::0,o::0,m::rwX,nginx:5,delan:7' /var/www/memories
# - provide /var/www/memories/peb/**
{ config, lib, options, modulesPath, pkgs, specialArgs }: with lib; {
  imports = [ ../lib ];

  internal = {
    hostId = "99D8468B";
    hostName = "colo";
    domain = "daz.cat";
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

      extraCommands = ''
        extip=103.108.231.122
        extip6=2404:f780:8:3006:cccc:ffff:feee:468b
        extif=bridge13

        for iptables in iptables ip6tables; do
          $iptables -P FORWARD DROP

          # iptables -A is not idempotent, so we need a way to remove old rules when we reload firewall.service.
          # we can’t just write our rules in -D/-A pairs because our old rules may be different to our new ones,
          # and we can’t just -F to flush the built-in chains because there are also rules added by libvirt etc.
          # if we instead encapsulate our rules in our own chains, then we can safely -F to flush any old rules.
          $iptables -N own-input || :
          $iptables -N own-output || :
          $iptables -N own-forward || :
          $iptables -t nat -N own-output || :
          $iptables -t nat -N own-prerouting || :
          $iptables -t nat -N own-postrouting || :
          $iptables -C INPUT -j own-input || $iptables -I INPUT -j own-input
          $iptables -C OUTPUT -j own-output || $iptables -A OUTPUT -j own-output
          $iptables -C FORWARD -j own-forward || $iptables -A FORWARD -j own-forward
          $iptables -t nat -C OUTPUT -j own-output || $iptables -t nat -A OUTPUT -j own-output
          $iptables -t nat -C PREROUTING -j own-prerouting || $iptables -t nat -A PREROUTING -j own-prerouting
          $iptables -t nat -C POSTROUTING -j own-postrouting || $iptables -t nat -A POSTROUTING -j own-postrouting
          $iptables -F own-input
          $iptables -F own-output
          $iptables -F own-forward
          $iptables -t nat -F own-output
          $iptables -t nat -F own-prerouting
          $iptables -t nat -F own-postrouting

          # accept forwarding virbr1 to extif
          $iptables -A own-forward -o $extif -i virbr1 -j ACCEPT

          # accept forwarding extif to virbr1 if established/related
          $iptables -A own-forward -i $extif -o virbr1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        done

        for proto in udp tcp; do
          # port forward dns to opacus
          iptables -A own-forward -i $extif -o virbr1 -p $proto --dport 53 -m conntrack --ctstate NEW -j ACCEPT
          iptables -t nat -A own-output -d $extip -p $proto --dport 53 -j DNAT --to-destination 172.19.130.245 # loopback
          iptables -t nat -A own-prerouting -i $extif -d $extip -p $proto --dport 53 -j DNAT --to-destination 172.19.130.245
          iptables -t nat -A own-postrouting -o virbr1 -p $proto --dport 53 -d 172.19.130.245 -j SNAT --to-source 172.19.130.1
          ip6tables -A own-forward -i $extif -o virbr1 -p $proto --dport 53 -m conntrack --ctstate NEW -j ACCEPT
          ip6tables -t nat -A own-output -d $extip6 -p $proto --dport 53 -j DNAT --to-destination fdfd:4524:784c:106d::2 # loopback
          ip6tables -t nat -A own-prerouting -i $extif -d $extip6 -p $proto --dport 53 -j DNAT --to-destination fdfd:4524:784c:106d::2
          ip6tables -t nat -A own-postrouting -o virbr1 -p $proto --dport 53 -d fdfd:4524:784c:106d::2 -j SNAT --to-source fdfd:4524:784c:106d::1

          # port forward for kate
          iptables -A own-forward -i $extif -o virbr1 -p $proto --dport 27025 -m conntrack --ctstate NEW -j ACCEPT
          iptables -t nat -A own-output -d $extip -p $proto --dport 27025 -j DNAT --to-destination 172.19.130.150 # loopback
          iptables -t nat -A own-prerouting -i $extif -d $extip -p $proto --dport 27025 -j DNAT --to-destination 172.19.130.150
          iptables -t nat -A own-postrouting -o virbr1 -p $proto --dport 27025 -d 172.19.130.150 -j SNAT --to-source 172.19.130.1
        done

        # nat outbound
        iptables -t nat -A own-postrouting -o bridge13 -j SNAT --to-source $extip
      '';
      allowedTCPPorts = [
        # nginx
        80 443
      ];
      allowedTCPPortRanges = [
        # libvirt migration
        { from = 49152; to = 49215; }
      ];
      allowedUDPPorts = [
        # dhcp
        67

        # nginx
        80 443
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
        "isbtrfsstableyet.com"
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
      ];
    };
  };
  users.users.nginx.extraGroups = [ "acme" ];

  services = {
    # colo network doesn’t have dhcp or dns, so we need our own dns server
    unbound = {
      enable = true;
      settings.forward-zone = [
        { name = "venus.tailcdc44b.ts.net"; forward-addr = "100.100.100.100"; }
        # FIXME: try {64..127}.100.in-addr.arpa. to fix avahi rdns hang on ping
      ];
    };

    openvpn.servers.home = {
      config = "config /etc/nixos/colo/home_colo.ovpn";
      autoStart = false;
    };
    tailscale = {
      enable = true;
      openFirewall = true;
    };

    nginx = {
      enable = true;
      # logError = "stderr notice";
      recommendedProxySettings = true;
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
        "azabani.com" = opacus // sslForce;
        "www.azabani.com" = opacus // sslForce;
        "ar1as.space" = opacus // sslForce;
        ".sixte.st" = stratus // sslRelax;
        "isbtrfsstableyet.com" = opacus // sslRelax;
        "kierang.ee.nroach44.id.au" = opacus // sslRelax;
        "shuppy.org" = sslShuppy // {
          locations."/" = {
            root = "/var/www/shuppy.org";
          };
        };
        "meet.shuppy.org" = {
          enableACME = false;
          useACMEHost = "shuppy.org";
        };
        "memories" = {
          listen = [{
            addr = "*";
            port = 20000;
            extraParameters = [ "default_server" ];
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
