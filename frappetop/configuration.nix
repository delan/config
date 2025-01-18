{ config, pkgs, lib, options, modulesPath, ... }: {
  imports = [ ../lib ];

  internal = {
    hostId = "6336419C";
    hostName = "frappetop";
    domain = "daz.cat";
    luksDevice = "/dev/disk/by-partlabel/frappetop.cuffs";
    bootDevice = "/dev/disk/by-partlabel/frappetop.esp";
    swapDevice = "/dev/disk/by-partlabel/frappetop.swap";
    separateNix = true;
    initialUser = "delan";

    interactive = true;
    laptop = true;
    igalia = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  nix.settings.sandbox = true;

  # biggest(?) available font
  console.font = "iso01-12x22";

  environment.systemPackages = with pkgs; [
    cifs-utils
    colordiff
    efibootmgr
    file
    gh  # for servo
    hdparm
    iftop
    iotop
    lm_sensors
    lsof
    ncdu
    ntfs3g
    pciutils
    samba
    tcpdump
    usbutils
  ];

  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
