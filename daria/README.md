daria.daz.cat
=============

OpenBSD [home router config](https://www.azabani.com/2015/08/06/modern-openbsd-home-router.html), initially deployed in 2015:

- nsd(8) was run on **opacus.daz.cat** (OpenBSD) between 2016-12 and 2018-11
- nsd(8) moved to **opacus.daz.cat** (OpenBSD) in 2021-09
- nsd(8) moved to **colo.daz.cat** (NixOS) in 2025-09
- everything else replaced with **jane.daz.cat** (OPNsense) in 2021-09
- config merged into [main config repo](https://github.com/delan/config.git) in 2025-09

how to update rdns
==================

```sh
$ cd /path/to/config/daria
$ cd var/nsd/zones
$ ./update-rdns.sh dry
$ ./update-rdns.sh wet
$ git diff
```
