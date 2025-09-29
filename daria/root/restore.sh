#!/bin/sh
set -eu -- \
	collectd-ping-- \
	colordiff-- \
	dkimproxy-- \
	git-- \
	htop-- \
	iftop-- \
	intel-firmware-- \
	iperf-- \
	miniupnpd-- \
	mosh-- \
	mtr-- \
	neofetch-- \
	nmap-- \
	nut-- \
	opendkim-- \
	openvpn-- \
	pciutils-- \
	pv-- \
	ripgrep-- \
	usbutils-- \
	vim--no_x11 \
	wide-dhcpv6-- \
	zsh-- \
#

pkg_add -- "$@"
yes n | pkg_delete -X -- "$@" quirks intel-firmware
