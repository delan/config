{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.services = {
    collectd = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal.services;
  in mkIf cfg.collectd {
    services.collectd = {
      enable = true;
      autoLoadPlugin = true;

      extraConfig = ''
        # FQDNLookup and NixOS/nixpkgs#47241 don’t seem to be easily compatible
        # https://github.com/NixOS/nixpkgs/issues/1248#issuecomment-303552124
        Hostname "${config.internal.hostName}"

        <Plugin network>
          # Server "172.19.128.121" "25826"
          Server "0.0.0.0" "25826"
        </Plugin>

        ReadThreads 5
        Interval 10
        Timeout 2

        LoadPlugin syslog
        LoadPlugin cpu
        LoadPlugin df
        LoadPlugin disk
        LoadPlugin interface
        LoadPlugin load
        LoadPlugin memory
        LoadPlugin processes
        LoadPlugin uptime
        LoadPlugin users
      '';
    };

    # for collectd.conf(5) FQDNLookup
    # consistent with NixOS/nixpkgs#47241
    networking.extraHosts = let
      long = config.internal.hostName;
      short = elemAt (builtins.split "[.]" long) 0;
    in ''
      127.0.0.1 ${long} ${short}
      ::1 ${long} ${short}
    '';
  };
}
