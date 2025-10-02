{ config, pkgs, lib, options, modulesPath, ... }: let
in {
  imports = [];

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
}
