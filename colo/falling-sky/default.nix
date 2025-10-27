{ config, pkgs, lib, options, modulesPath, ... }: with lib; let
  cfg = config.services.falling-sky;
in {
  imports = [ ./nsd.nix ];

  options = with lib; {
    services.falling-sky = {
      enable = mkOption { type = types.bool; default = false; };
      domain = mkOption { type = types.str; };
      ipv4-address = mkOption { type = types.str; };
      ipv6-address = mkOption { type = types.str; };
      mtu1280-address = mkOption { type = types.str; };
      v6ns-soa-rname = mkOption {
        type = types.str;
        defaultText = literalExpression "hostmaster.\${services.falling-sky.domain}.";
      };
      v6ns-acme-challenge-cname = mkOption { type = types.str; };
    };
  };

  config = lib.mkIf cfg.enable {
    services.falling-sky.v6ns-soa-rname = lib.mkDefault "hostmaster.${cfg.domain}.";

    services.httpd = {
      enable = true;
      # <https://github.com/falling-sky/source/wiki/InstallApachePHP>
      enablePHP = true;
      # <https://github.com/falling-sky/source/wiki/InstallApacheVirtualHost>
      virtualHosts = {
        "${cfg.domain}" = let
          # <https://github.com/falling-sky/source/wiki/InstallContent>
          # mkdir -pv /var/www/${cfg.domain}
          # rsync -a --del --exclude=site fsky@rsync.test-ipv6.com:stable/content/ /var/www/${cfg.domain}
          documentRoot = "/var/www/${cfg.domain}";
        in {
          listen = [
            { ip = "127.0.0.1"; port = 1280; }
          ];
          inherit documentRoot;
          extraConfig = ''
            <Directory "${documentRoot}">
              Options MULTIVIEWS Indexes FollowSymLinks
              AllowOverride ALL
              Order allow,deny
              Allow from all
            </Directory>
          '';
        };
      };
      # <https://github.com/falling-sky/source/wiki/InstallModIP>
      extraModules = [
        { name = "mod_ip"; path = pkgs.callPackage ./mod_ip.nix {}; }
      ];
    };

    # <https://github.com/falling-sky/source/wiki/InstallDNS>
    networking.networkmanager.ensureProfiles.profiles.bridge13.ipv6 = {
      address1 = "${cfg.ipv6-address}/64";
      address2 = "${cfg.mtu1280-address}/64";
    };
    services.falling-sky.nsd = {
      enable = true;
      interfaces = [cfg.ipv6-address];
      zones = let
        zone = name: filename: options: {
          name = "${name}.";
          value = {
            data = lib.readFile ./${filename};
          } // options;
        };
      in {
        "v6ns1.${cfg.domain}." = {
          data = ''
            ;################################################################
            ;# ZONE: v6ns1.${cfg.domain}.
            ;# Put this on the VM operating your test-ipv6.com mirror.
            ;# Do NOT put this on your main DNS server.
            ;################################################################

            $TTL 300
            @ IN SOA v6ns1.${cfg.domain}. ${cfg.v6ns-soa-rname} (
              2025100300 ; Serial
              86400 ; Refresh
              7200  ; Retry
              604800 ; Expire
              172800) ; Minimum

                NS  v6ns1.${cfg.domain}.
                AAAA  ${cfg.ipv6-address}
          '';
        };
        "v6ns.${cfg.domain}." = {
          data = ''
            ;################################################################
            ;# ZONE: v6ns.${cfg.domain}.
            ;# Put this on the VM operating your test-ipv6.com mirror.
            ;# Do NOT put this on your main DNS server.
            ;################################################################

            $TTL 300
            @ IN SOA v6ns1.${cfg.domain}. ${cfg.v6ns-soa-rname} (
              2025100300 ; Serial
              86400 ; Refresh
              7200  ; Retry
              604800 ; Expire
              172800) ; Minimum

                NS  v6ns1.${cfg.domain}.

            ; Specific records for tests
            ipv4    A ${cfg.ipv4-address}
            ipv6    AAAA  ${cfg.ipv6-address}
            ds    A ${cfg.ipv4-address}
            ds    AAAA  ${cfg.ipv6-address}
            a   A ${cfg.ipv4-address}
            aaaa    AAAA  ${cfg.ipv6-address}
            www4    A ${cfg.ipv4-address}
            www6    AAAA  ${cfg.ipv6-address}
            v4    A ${cfg.ipv4-address}
            v6    AAAA  ${cfg.ipv6-address}


            _acme-challenge CNAME ${cfg.v6ns-acme-challenge-cname}
          '';
        };
      };
    };

    # <https://github.com/falling-sky/source/wiki/InstallPMTUD>
    # FIXME you may want to reboot if you change `mtu1280-address`
    networking.firewall.extraCommands = ''
      ip6tables -t mangle -C PREROUTING -d ${cfg.mtu1280-address} -j NFQUEUE --queue-num 1280 \
      || ip6tables -t mangle -A PREROUTING -d ${cfg.mtu1280-address} -j NFQUEUE --queue-num 1280
    '';
    systemd.services.fsky-mtu1280d = {
      wantedBy = ["multi-user.target"];
      script = ''
        ${pkgs.callPackage ./mtu1280d.nix {}}
      '';
    };
  };
}
