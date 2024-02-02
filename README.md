daria.daz.cat
=============

Home router, now decommissioned in favour of **jane.daz.cat** (OPNsense).

* /var/nsd continues to be maintained, but lives on **opacus.daz.cat**
* more details: <https://www.azabani.com/2015/08/06/modern-openbsd-home-router.html>

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
