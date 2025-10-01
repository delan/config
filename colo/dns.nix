{ config, lib, options, modulesPath, pkgs, specialArgs }: with lib; {
  services.nsd = {
    enable = true;
    interfaces = ["103.108.231.122" "2404:f780:8:3006:cccc:ffff:feee:468b"];
    zones = let
      zone = name: filename: options: {
        name = "${name}.";
        value = {
          data = readFile ../daria/var/nsd/zones/${filename};
        } // options;
      };
      provideXFR = [
        "144.6.130.75 NOKEY" # home.daz.cat
        "216.218.133.2 NOKEY" # dns.he.net outbound
        "69.65.50.192 NOKEY" # afraid.org outbound
      ];
      notify = [
        "216.218.130.2 NOKEY" # ns1.he.net
        "69.65.50.223 NOKEY" # ns2.afraid.org
      ];
    in listToAttrs [
      (zone "daz.cat" "daz.cat.zone" {
        inherit provideXFR notify;
      })
      (zone "tail.daz.cat" "tail.daz.cat.zone" {
        inherit provideXFR;
      })
      (zone "home.daz.cat" "home.daz.cat.zone" {
        inherit provideXFR;
      })
      (zone "acme.daz.cat" "acme.daz.cat.zone" {
        # do not provideXFR here!
        requestXFR = ["127.0.0.1@55 NOKEY"];
      })
      (zone "azabani.com" "azabani.com.zone" {
        inherit provideXFR notify;
      })
      (zone "shuppy.org" "shuppy.org.zone" {
        inherit provideXFR notify;
      })
      (zone "acme.shuppy.org" "acme.shuppy.org.zone" {
        # do not provideXFR here!
        requestXFR = ["127.0.0.1@55 NOKEY"];
      })
      (zone "42.19.172.in-addr.arpa" "172.19.42.24.zone" {
        inherit provideXFR;
      })
      (zone "129.19.172.in-addr.arpa" "172.19.129.24.zone" {
        inherit provideXFR;
      })
      (zone "130.19.172.in-addr.arpa" "172.19.130.24.zone" {
        inherit provideXFR;
      })
      (zone "6.0.0.3.8.0.0.0.0.8.7.f.4.0.4.2.ip6.arpa" "2404.f780.8.3006.64.zone" {
        inherit provideXFR;
      })
      (zone "4.1.2.0.e.0.8.5.3.0.4.2.ip6.arpa" "2403.580e.214.48.zone" {
        inherit provideXFR;
      })
      (zone "e.c.9.2.2.2.3.4.f.e.9.0.6.3.d.f.ip6.arpa" "fd36.09ef.4322.29ce.64.zone" {
        inherit provideXFR;
      })
    ];
  };

  services.powerdns = {
    enable = true;
    extraConfig = ''
      local-port=55
      launch=gsqlite3
      gsqlite3-database=/var/lib/shuppy/pdns-acme/pdns-acme.sqlite
      dnsupdate=yes
      # venus.tailcdc44b.ts.net. = 100.95.253.127
      allow-dnsupdate-from=127.0.0.1/32 100.95.253.127/32
    '';
  };

  systemd.services.pdns-acme = {
    wantedBy = ["multi-user.target"];
    script = ''
      mkdir -p /var/lib/shuppy/pdns-acme
      chown pdns:pdns /var/lib/shuppy/pdns-acme
    '';
  };

  systemd.services.pdns = {
    after = ["pdns-acme.service"];
    preStart = ''
      # keep existing database if possible, to avoid rewinding SOA serials
      if ! [ -e /var/lib/shuppy/pdns-acme/pdns-acme.sqlite ]; then
        ${pkgs.sqlite}/bin/sqlite3 -init ${pkgs.copyPathToStore ../colo/pdns-acme.sql} /var/lib/shuppy/pdns-acme/pdns-acme.sqlite
        ${pkgs.pdns}/bin/pdnsutil create-zone acme.daz.cat
        ${pkgs.pdns}/bin/pdnsutil load-zone acme.daz.cat ${pkgs.copyPathToStore ../daria/var/nsd/zones/acme.daz.cat.zone}
        ${pkgs.pdns}/bin/pdnsutil create-zone acme.shuppy.org
        ${pkgs.pdns}/bin/pdnsutil load-zone acme.shuppy.org ${pkgs.copyPathToStore ../daria/var/nsd/zones/acme.shuppy.org.zone}
      fi
      chmod 600 /var/lib/shuppy/pdns-acme/pdns-acme.sqlite
    '';
  };
}
