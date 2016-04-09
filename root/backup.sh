#!/bin/sh

out=$(mktemp -td daria.backup.XXXXXX)
ball=$(mktemp -t daria.backup.XXXXXX)
cd $out

mkdir -p etc/rc.d etc/ssh root
mkdir -p etc/openvpn var/run/openvpn
mkdir -p var/unbound/etc
cp /etc/myname etc
cp /etc/sysctl.conf etc
cp /etc/resolv.conf etc
cp /etc/hostname.* etc
cp /etc/pf.conf etc
cp /etc/dhclient.conf etc
cp /etc/dhcpd.conf etc
cp /etc/dhcp6c.conf etc
cp /etc/ntpd.conf etc
cp /var/unbound/etc/unbound.conf var/unbound/etc
cp /etc/rc.d/dhcp6c etc/rc.d
cp /etc/rc.conf.local etc
cp /etc/ssh/sshd_config etc/ssh
cp /root/backup.sh root
cp /etc/openvpn/*.conf etc/openvpn
cp /var/run/openvpn/.keep var/run/openvpn

tar cvpf $ball *
mv $ball $ball.tar
echo $ball.tar
