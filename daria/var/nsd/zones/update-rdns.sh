#!/usr/bin/env zsh
# usage: update-rdns.sh <dry|wet>
set -euo pipefail

drywet=$1

if [ "$drywet" = dry ]; then echo '>>> 2404.f780.8.3006.64.zone' >&2; fi
rg 2404:f780:8:3006: daz.cat.zone | fgrep -ve '@ ' -e 'ns ' \
| ./update-rdns-for-zone.sh 2404.f780.8.3006.64.zone daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi

if [ "$drywet" = dry ]; then echo '>>> 2403.580e.214.48.zone' >&2; fi
rg 2403:580e:214:0: daz.cat.zone \
| ./update-rdns-for-zone.sh 2403.580e.214.48.zone daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi

if [ "$drywet" = dry ]; then echo '>>> 172.19.42.24.zone' >&2; fi
rg 172.19.42. home.daz.cat.zone \
| ./update-rdns-for-zone.sh 172.19.42.24.zone home.daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi

if [ "$drywet" = dry ]; then echo '>>> fd36.09ef.4322.29ce.64.zone' >&2; fi
rg fd36:09ef:4322:29ce: daz.cat.zone \
| ./update-rdns-for-zone.sh fd36.09ef.4322.29ce.64.zone daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi

if [ "$drywet" = dry ]; then echo '>>> 172.19.129.24.zone' >&2; fi
rg 172.19.129. daz.cat.zone \
| ./update-rdns-for-zone.sh 172.19.129.24.zone daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi

if [ "$drywet" = dry ]; then echo '>>> 172.19.130.24.zone' >&2; fi
rg 172.19.130. daz.cat.zone \
| ./update-rdns-for-zone.sh 172.19.130.24.zone daz.cat "$drywet"
if [ "$drywet" = dry ]; then echo >&2; fi
