#!/usr/bin/env zsh
set -eu

# smart id, row label, formatting prefix
attributes=( \
	5 Reallocated_Sector_Ct $(tput setaf 9) \
	9 Power_On_Hours '' \
	196 Reallocated_Event_Count $(tput setaf 9) \
	197 Current_Pending_Sector $(tput setaf 9) \
	198 Offline_Uncorrectable $(tput setaf 9) \
	199 UDMA_CRC_Error_Count '' \
	193 Load_Cycle_Count '' \
	194 Temperature_Celsius '' \
)

printcol() {
	printf \%-13s "$@"
}

printbar() {
	printf \%s '-------------'
}

scratch=$(mktemp -d)
n=$#

# print device headings and cache smartctl output
tput bold
i=0; while [ $i -lt $n ]; do
	f=$1; shift
	printcol ${f#/dev/}
	e=0; > $scratch/$i sudo smartctl -a $f || e=$?
	if [ $e -gt 0 ] && [ $e -lt 8 ]; then exit $e; fi
	set -- "$@" "$f"
	i=$((i+1))
done
echo
tput sgr0

# print partlabel of a partition on each disk
i=0; while [ $i -lt $n ]; do
	f=$1; shift
	printcol $(paste <(cd /dev/disk/by-partlabel; printf \%s\\n *) <(readlink /dev/disk/by-partlabel/*) | rg ${f#/dev/} | cut -f 1 | sed q)
	set -- "$@" "$f"
	i=$((i+1))
done
echo

i=0; while [ $i -lt $n ]; do
	printbar
	i=$((i+1))
done
echo

i=0; while [ $i -lt $n ]; do
	printcol $(< $scratch/$i sed -E '/^SMART overall-health self-assessment test result: /!d;s///')
	i=$((i+1))
done
echo overall-health

while [ $#attributes -gt 0 ]; do
	id=$attributes[1]; shift 1 attributes
	name=$attributes[1]; shift 1 attributes
	formatting=$attributes[1]; shift 1 attributes
	printf \%s "$formatting"

	i=0; while [ $i -lt $n ]; do
		printcol $(< $scratch/$i egrep '^ {0,2}'$id | cut -c 88- | sed -E 's/ \(Min\/Max [^)]+\)//')
		i=$((i+1))
	done

	echo $name
	tput sgr0
done
