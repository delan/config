{ config, lib, options, modulesPath, pkgs, ... }: with lib; {
  options.internal.services = {
    qbittorrent = mkOption { type = types.bool; default = false; };
  };

  config = let
    cfg = config.internal.services;
    home = "/var/lib/qbittorrent";
    webuiPort = config.internal.ids.qbittorrent.port;
    torrentPort = config.internal.ids.qbittorrent.port + 1;
  in mkIf cfg.qbittorrent {
    networking.firewall = {
      allowedTCPPorts = [ webuiPort torrentPort ];
      allowedUDPPorts = [ webuiPort torrentPort ];
    };

    systemd.services.qbittorrent = {
      # https://github.com/pceiley/nix-config/blob/3854c687d951ee3fe48be46ff15e8e094dd8e89f/hosts/common/modules/qbittorrent.nix
      # https://github.com/qbittorrent/qBittorrent/blob/bfd3ce2fca804ef3d0b1712503a0e56e20aa62c7/dist/unix/systemd/qbittorrent-nox%40.service.in
      description = "qBittorrent-nox service";
      documentation = [ "man:qbittorrent-nox(1)" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "qbittorrent";
        Group = "qbittorrent";
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
      };

      environment = {
        QBT_PROFILE = home;
        QBT_WEBUI_PORT = toString webuiPort;
      };
    };
  };
}
