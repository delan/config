#!/bin/sh
if [ -n "${DISPLAY+set}" ]; then
  >&2 echo 'fatal: check failed: $DISPLAY is set'
  exit 1
fi
if [ -n "${WAYLAND_DISPLAY+set}" ]; then
  >&2 echo 'fatal: check failed: $WAYLAND_DISPLAY is set'
  exit 1
fi
if systemctl is-active display-manager.service > /dev/null 2>&1; then
  >&2 echo 'fatal: check failed: `systemctl is-active display-manager.service`'
  exit 1
fi
if pgrep -x i3 > /dev/null 2>&1; then
  >&2 echo 'fatal: check failed: `pgrep -x i3`'
  exit 1
fi
echo 'let'\''s play some games!!'
sleep 3
export LIBVIRT_DEFAULT_URI=qemu:///system
virsh start fsx-uefi
