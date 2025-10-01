#!/usr/bin/env zsh
# usage: rg 192.0.2. path/to/forward/zone | update-rdns-for-zone.sh <path/to/reverse/zone> <suffix.daz.cat> <dry|wet>
set -euo pipefail

zone=$1
suffix=$2
drywet=$3

< "$zone" head -1 | cut -d\( -f2 | read -r oldserial _
newserial=$(date -u +\%Y\%m\%d00)
while [ $newserial -le $oldserial ]; do
  newserial=$((newserial+1))
done

case "$drywet" in
(dry) out=/dev/stdout ;;
(wet) out=$zone ;;
(*) >&2 echo 'fatal: $2 must be dry or wet'; exit 1 ;;
esac

> "$out" echo "@ 60 IN SOA ns.daz.cat. delan.azabani.com. ( $newserial 600 60 1814400 60 )"
>> "$out" echo "@ 60 IN NS ns.daz.cat."
while read -r name _ _ _ ip; do
  # bore encode/decode so we don’t actually send the query
  bore --encode -x "$ip" | bore --decode | rg -A1 '^;; question section$' | tail -1 | read -r reverse _
  >> "$out" echo "$reverse 60 IN PTR $name.$suffix."
done
