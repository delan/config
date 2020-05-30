#!/bin/sh
set -eu

if [ $# -lt 1 ]; then
	set -- "$@" $(mktemp -td backup.XXXXXXX)
fi

if [ $# -lt 2 ]; then
	set -- "$@" $(mktemp -t backup.XXXXXXX | sed s/\$/.tar/)
fi

>&2 printf \%s\\n "$1" "$2"
cd -- "$1"

mkdir -p etc/rc.d etc/ssh root
mkdir -p etc/mail
mkdir -p etc/openvpn
mkdir -p etc/.local/DKIM
mkdir -p var/nsd/etc var/nsd/zones
mkdir -p var/unbound/etc
cp /etc/myname etc
cp /etc/installurl etc
cp /etc/sysctl.conf etc
cp /etc/resolv.conf etc
cp /etc/hostname.* etc
cp /etc/pf.conf etc
cp /etc/dhclient.conf etc
cp /etc/dhcpd.conf etc
cp /etc/dhcp6c.conf etc
cp /etc/dhcp6s.conf etc
cp /etc/rad.conf etc
cp /etc/ntpd.conf etc
cp /var/nsd/etc/nsd.conf var/nsd/etc
cp /var/nsd/zones/*.zone var/nsd/zones
cp /var/unbound/etc/unbound.conf var/unbound/etc
cp /etc/rc.d/mi.subr etc/rc.d
cp /etc/rc.d/dhcp6c etc/rc.d
cp /etc/rc.d/dhcp6s etc/rc.d
cp /etc/rc.d/openvpn etc/rc.d
ln -sf openvpn etc/rc.d/openvpn__chi
cp /etc/rc.conf.local etc
cp /etc/ssh/sshd_config etc/ssh
cp /etc/mail/smtpd.conf etc/mail
cp /etc/dkimproxy_in.conf etc
cp /etc/dkimproxy_out.conf etc
cp /etc/.local/DKIM/*.txt etc/.local/DKIM
cp /root/backup.sh root
cp /etc/openvpn/chi.conf etc/openvpn

tar cf "$2" *
