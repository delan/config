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
    tailscale = true;

    virtualisation = {
      libvirt = true;
      docker = true;
    };
  };

  # systemd.mount(5) units for ocean nfs (venus.tailcdc44b.ts.net.); we can’t use `fileSystems` and
  # fstab(5) because there’s no `x-systemd` option for arbitrary `BindsTo=`
  systemd.mounts = let
    nfsOverTailscale = {
      after = ["tailscaled.service"];
      bindsTo = ["tailscaled.service"];
      wantedBy = ["remote-fs.target"];
      # make sure we get the Default Dependencies for network mounts (see systemd.mount(5)),
      # ensuring network-online.target shows up in `systemctl list-dependencies ocean.mount`;
      # this is more “correct” but probably not critical since `After=tailscaled.service`
      type = "nfs";
      # translated the fstab(5) `rw,soft,bg` to systemd.mount(5); systemd.automount(5) sounds like
      # it would be nice here, but i get ordering cycles with `WantedBy=remote-fs.target` for some
      # reason. these ordering cycles cause random services to not longer get started on boot :):)
      # “The NFS mount option bg for NFS background mounts as documented in nfs(5) is detected by
      # systemd-fstab-generator and the options are transformed so that systemd fulfills the
      # job-control implications of that option. Specifically systemd-fstab-generator acts as
      # though "x-systemd.mount-timeout=infinity,retry=10000" was prepended to the option list, and
      # "fg,nofail" was appended. Depending on specific requirements, it may be appropriate to
      # provide some of these options explicitly, or to make use of the "x-systemd.automount"
      # option described below instead of using "bg".”
      options = "retry=10000,rw,soft,fg,nofail";
      mountConfig = {
        TimeoutSec = "infinity";
      };
    };
  in [
    (nfsOverTailscale // {
      name = "ocean.mount";
      what = "100.95.253.127:/ocean";
      where = "/ocean";
    })
    (nfsOverTailscale // {
      name = "ocean-active.mount";
      what = "100.95.253.127:/ocean/active";
      where = "/ocean/active";
    })
    (nfsOverTailscale // {
      name = "ocean-private.mount";
      what = "100.95.253.127:/ocean/private";
      where = "/ocean/private";
    })
    (nfsOverTailscale // {
      name = "ocean-public.mount";
      what = "100.95.253.127:/ocean/public";
      where = "/ocean/public";
    })
  ];

  nix.settings.sandbox = true;

  # biggest(?) available font
  console.font = "iso01-12x22";

  networking = {
    firewall = {
      allowedTCPPorts = [
        8000 # for servo ci monitor
      ];

      allowedUDPPorts = [
      ];
    };
  };

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
    nfs-utils
    ntfs3g
    pciutils
    samba
    tcpdump
    usbutils

    cdrkit  # for servo/ci-runners
    gh  # for servo/ci-runners
    hivex  # for servo/ci-runners
    jq  # for servo/ci-runners
    unzip  # for servo/ci-runners
  ];

  fonts.fontconfig.defaultFonts.monospace = [ "monofur" ];
}
