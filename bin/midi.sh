#!/bin/sh
set -eu
exec nohup timidity -iA -B2,8 -Os1l -s 44100 -x "soundfont $(nix eval --raw nixos.soundfont-fluid.outPath)/share/soundfonts/FluidR3_GM2-2.sf2 order=1" > $(mktemp /tmp/midi..XXXXXXXXXXXXX | tee /dev/stderr) &
