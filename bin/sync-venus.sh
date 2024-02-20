#!/usr/bin/env zsh
set -euo shwordsplit
# echo sync disabled; exit 1

rsh=''
src_prefix=cuffs
dest_prefix=ocean/dump/venus

new=$(date -u +\%FT\%RZ)
echo ">>> new: $new"

zfs snapshot -r cuffs@$new
for i in cuffs cuffs/storage/swap; do
  zfs destroy -v $i@$new
done

for i in home root storage{,/data}; do
  echo ">>> syncing $src_prefix/$i"
  unset old
  set -- -t bookmark -Ho name -d 1 $src_prefix/$i
  if [ $(zfs list "$@" | wc -l) -eq 0 ]; then
    echo "fatal: no bookmarks in $src_prefix/$i"
    exit 1
  fi
  zfs list "$@" | sed 's/.*#//' | tac | while read -r j; do
    echo "=== checking for snapshot on destination: $dest_prefix/$i@$j"
    # redirect to prevent ssh from stealing stdin
    if $rsh zfs list -t snapshot -Ho name $dest_prefix/$i@$j < /dev/null; then
      old=$j
      break
    fi
  done
  if [ -z "${old+set}" ]; then
    echo "fatal: no bookmark has snapshot on destination: $src_prefix/$i"
    exit 1
  fi
  echo "=== old: $old"
  ~delan/bin/zfs-sync-snapshots --bookmark --delete this --i-am-a-cron-job-fuck-me-up-and-delete-without-asking --rsh "$rsh" $dest_prefix $src_prefix/$i --incremental-source \#$old $new wet
done
