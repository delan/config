#!/usr/bin/env zsh
set -eu

attributes=( \
	5 Reallocated_Sector_Ct \
	9 Power_On_Hours \
	196 Reallocated_Event_Count \
	197 Current_Pending_Sector \
	198 Offline_Uncorrectable \
	199 UDMA_CRC_Error_Count \
	193 Load_Cycle_Count \
	194 Temperature_Celsius \
)

printcol() {
	printf \%-13s "$@"
}

scratch=$(mktemp -d)
n=$#

i=0
while [ $i -lt $n ]; do
	f=$1; shift
	printcol ${f#/dev/}
	e=0; > $scratch/$i sudo smartctl -a $f || e=$?
	if [ $e -gt 0 ] && [ $e -lt 8 ]; then exit $e; fi
	set -- "$@" "$f"
	i=$((i+1))
done

echo

# i=0
# while [ $i -lt $n ]; do
# 	f=$1; shift
# 	printcol $(sudo camcontrol devlist | sed -E 's/.*> + at //;s/ target / /;s/ lun /:/g;s/[()]//g;s/,/ /g;s/ pass[^ ]+//' | rg ' '${f#/dev/}'$' | while read -r k a d; do printf \%s\\n $(sudo camcontrol devlist -b | sed 's/ bus /:/;s/ on / /' | rg '^'$k' ' | cut -d ' ' -f2):$a; done)
# 	set -- "$@" "$f"
# 	i=$((i+1))
# done

# echo

# i=0
# while [ $i -lt $n ]; do
# 	f=$1; shift
# 	printcol $(geom part list $f | rg -o --pcre2 '(?<=^   label: ).*')
# 	set -- "$@" "$f"
# 	i=$((i+1))
# done

# echo

i=0
while [ $i -lt $n ]; do
	f=$1; shift
  printcol $(paste <(cd /dev/disk/by-partlabel; printf \%s\\n *) <(readlink /dev/disk/by-partlabel/*) | rg ${f#/dev/} | cut -f 1 | sed q)
	set -- "$@" "$f"
	i=$((i+1))
done

echo

i=0
while [ $i -lt $n ]; do
	printcol $(< $scratch/$i sed -E '/^SMART overall-health self-assessment test result: /!d;s///')
	i=$((i+1))
done

echo overall-health

while [ $#attributes -gt 0 ]; do
	id=$attributes[1]; shift 1 attributes
	name=$attributes[1]; shift 1 attributes

	i=0
	while [ $i -lt $n ]; do
		printcol $(< $scratch/$i egrep '^ {0,2}'$id | cut -c 88- | sed -E 's/ \(Min\/Max [^)]+\)//')
		i=$((i+1))
	done

	echo $name
done
