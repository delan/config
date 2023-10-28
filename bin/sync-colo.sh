#!/usr/bin/env zsh
set -euo shwordsplit

rsh='ssh delan@storage.home.daz.cat sudo'
src_prefix=cuffs
dest_prefix=ocean/dump/colo

new=$(date -u +\%FT\%RZ)
echo ">>> new: $new"

zfs snapshot -r cuffs@$new
for i in cuffs cuffs/{cache.nginx,nix}; do
  zfs destroy -v $i@$new
done

for i in home kate{,/vm0} opacus{,.www} root stratus.{vda,vdb}; do
  echo ">>> syncing $src_prefix/$i"
  unset old
  zfs list -t bookmark -Ho name -d 1 $src_prefix/$i | sed 's/.*#//' | tac | while read -r j; do
    if $rsh zfs list -t snapshot -Ho name $dest_prefix/$i@$j; then
      old=$j
      break
    fi
  done
  echo "=== old: $old"
  ~delan/bin/zfs-sync-snapshots --bookmark --delete all --delete-yes --rsh "$rsh" $dest_prefix $src_prefix/$i --incremental-source \#$old $new wet
done
