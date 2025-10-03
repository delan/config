{ config, pkgs, lib, options, modulesPath, ... }: let
in {
  imports = [ ./nsd.nix ];

  services.httpd = {
    enable = true;
    # <https://github.com/falling-sky/source/wiki/InstallApachePHP>
    enablePHP = true;
    # <https://github.com/falling-sky/source/wiki/InstallApacheVirtualHost>
    virtualHosts = {
      "sixte.st" = let
        # <https://github.com/falling-sky/source/wiki/InstallContent>
        # mkdir -pv /var/www/sixte.st
        # rsync -a --del --exclude=site fsky@rsync.test-ipv6.com:stable/content/ /var/www/sixte.st
        documentRoot = "/var/www/sixte.st";
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
    extraModules = let
      mod_ip = pkgs.stdenv.mkDerivation rec {
        pname = "mod_ip";
        version = "1.0+2025.03.03";
        src = pkgs.fetchFromGitHub {
          owner = "falling-sky";
          repo = "mod_ip";
          rev = "03c17be48cf61145ca98416d6af7505594a2183c";
          hash = "sha256-HOprMJr+WxBL86+glc5D6raw62oAWYM5s+GdCrd6LGc=";
        };
        nativeBuildInputs = [
          pkgs.apacheHttpd
        ];
        # <https://stackoverflow.com/a/27571222>
        installPhase = ''
          cp -v .libs/mod_ip.so $out
        '';
      };
    in [
      { name = "mod_ip"; path = mod_ip; }
    ];
  };

  # <https://github.com/falling-sky/source/wiki/InstallDNS>
  networking.networkmanager.ensureProfiles.profiles.bridge13.ipv6 = {
    address1 = "2404:f780:8:3006::468b:1500/64";
    address2 = "2404:f780:8:3006::468b:1280/64";
  };
  services.falling-sky.nsd = {
    enable = true;
    interfaces = ["2404:f780:8:3006::468b:1500"];
    zones = let
      zone = name: filename: options: {
        name = "${name}.";
        value = {
          data = lib.readFile ./${filename};
        } // options;
      };
    in lib.listToAttrs [
      (zone "v6ns1.sixte.st" "v6ns1.sixte.st.zone" {})
      (zone "v6ns.sixte.st" "v6ns.sixte.st.zone" {})
    ];
  };

  # <https://github.com/falling-sky/source/wiki/InstallPMTUD>
  networking.firewall.extraCommands = ''
    ip6tables -t mangle -C PREROUTING -d 2404:f780:8:3006::468b:1280 -j NFQUEUE --queue-num 1280 \
    || ip6tables -t mangle -A PREROUTING -d 2404:f780:8:3006::468b:1280 -j NFQUEUE --queue-num 1280
  '';
  systemd.services.fsky-mtu1280d = {
    wantedBy = ["multi-user.target"];
    script = ''
      ${pkgs.callPackage ./mtu1280d.nix {}}
    '';
  };
}
