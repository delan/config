daria.daz.cat
=============

OpenBSD [home router config](https://www.azabani.com/2015/08/06/modern-openbsd-home-router.html), initially deployed in 2015:

- nsd(8) was run on **opacus.daz.cat** (OpenBSD) between 2016-12 and 2018-11
- nsd(8) moved to **opacus.daz.cat** (OpenBSD) in 2021-09
- nsd(8) moved to **colo.daz.cat** (NixOS) in 2025-09
- everything else replaced with **jane.daz.cat** (OPNsense) in 2021-09
- config merged into [main config repo](https://github.com/delan/config.git) in 2025-09

how to commit changes
=====================

```sh
$ cd ~/daria.daz.cat && root/backup.sh && git add -N . && git commit -p
```

how to update rdns
==================

```sh
$ cd /var/nsd/zones
$ rg 2404:f780:8:3006: daz.cat.zone | fgrep -ve '@ ' -e 'ns ' | ./update-rdns.sh 2404.f780.8.3006.64.zone daz.cat dry
$ rg 2403:580e:214:0: daz.cat.zone | ./update-rdns.sh 2403.580e.214.48.zone daz.cat dry
$ rg 172.19.42. home.daz.cat.zone | ./update-rdns.sh 172.19.42.24.zone home.daz.cat dry
$ rg fd36:09ef:4322:29ce: daz.cat.zone | ./update-rdns.sh fd36.09ef.4322.29ce.64.zone daz.cat dry
$ rg 172.19.129. daz.cat.zone | ./update-rdns.sh 172.19.129.24.zone daz.cat dry
$ rg 172.19.130. daz.cat.zone | ./update-rdns.sh 172.19.130.24.zone daz.cat dry
```
