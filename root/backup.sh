#!/bin/sh

out=$(mktemp -td daria.backup.XXXXXX)
ball=$(mktemp -t daria.backup.XXXXXX)
cd $out

mkdir -p etc/rc.d etc/ssh root
cp /etc/myname etc
cp /etc/sysctl.conf etc
cp /etc/resolv.conf etc
cp /etc/hostname.* etc
cp /etc/pf.conf etc
cp /etc/dhcpd.conf etc
cp /etc/dhcp6c.conf etc
cp /etc/ntpd.conf etc
cp /etc/rc.d/dhcp6c etc/rc.d
cp /etc/rc.conf.local etc
cp /etc/ssh/sshd_config etc/ssh
cp /root/backup.sh root

sed -E 's/authkey .+/authkey redacted/' \
	< /etc/hostname.pppoe0 > etc/hostname.pppoe0

sed -E 's/wpakey .+/wpakey redacted/' \
	< /etc/hostname.ral* > etc/hostname.ral*

tar cvpf $ball *
mv $ball $ball.tar
echo $ball.tar
