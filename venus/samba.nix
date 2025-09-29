{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  config = {
    services.samba = {
      enable = true;
      package = pkgs.samba4Full;
      settings.global = {
        "log level" = 3;
        "syslog" = 3;
        "map to guest" = "Bad User";
        "guest account" = "nobody";

        # note that xattrs work on zfs and freebsd < 13
        # it’s just the xattr *property* that fails
        # ea support = yes # default
        # vfs objects = streams_xattr # don’t use
        "create mode" = "0775"; # like umask 002
        "directory mode" = "0775"; # like umask 002
        # force create mode = 0111 # for +x by default
        # store dos attriibutes = yes # default

        # still needed (man page is wrong)
        "map archive" = "no";
        "map system" = "no";
        "map hidden" = "no";
      };
      shares = {
        ocean = {
          path = "/ocean";
          "read only" = "no";
          "guest ok" = "yes";
          "hide dot files" = "no";

          # “No child processes” error?
          # make sure samba can find the shebang (/bin/sh works, /usr/bin/env zsh does not)
          # otherwise make sure you chown root + chmod 755
          "dfree command" = "/run/current-system/sw/bin/ocean-dfree.sh";
        };
        scanner = {
          path = "/ocean/active/scanner";
          "read only" = "no";
          "guest ok" = "no";
          "hide dot files" = "no";
        };
        paperless = {
          path = "/ocean/active/services/paperless/inbox";
          "read only" = "no";
          "guest ok" = "no";
          "hide dot files" = "no";
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 139 445 ];
      allowedUDPPorts = [ 137 138 ];
    };
  };
}
