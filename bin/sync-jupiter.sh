#!/usr/bin/env zsh
set -euo shwordsplit
# echo sync disabled; exit 1

rsh='ssh delan@venus.home.daz.cat sudo'

new=$(date -u +\%FT\%RZ)
echo ">>> new: $new"

zfs snapshot -r cuffs@$new
zfs list -Ho name -r cuffs | rg '^cuffs/(base|build|ci|nix)(/|$)' | while read -r i; do
  zfs destroy -v $i@$new
done

src_dest_pairs=(
  cuffs/code ocean/dump/jupiter/code
  cuffs/home ocean/dump/jupiter/home
  cuffs/root ocean/dump/jupiter/root
  cuffs/darktable ocean/private/shuppy/darktable
)
while [ ${#src_dest_pairs} -gt 0 ]; do
  src_dataset=${src_dest_pairs[1]}; shift src_dest_pairs
  dest_dataset=${src_dest_pairs[1]}; shift src_dest_pairs
  echo ">>> syncing $src_dataset → $dest_dataset"
  unset old
  set -- -t bookmark -Ho name -d 1 $src_dataset
  if [ $(zfs list "$@" | wc -l) -eq 0 ]; then
    echo "fatal: no bookmarks in $src_dataset"
    exit 1
  fi
  zfs list "$@" | sed 's/.*#//' | tac | while read -r j; do
    echo "=== checking for snapshot on destination: $dest_dataset@$j"
    # redirect to prevent ssh from stealing stdin
    if $rsh zfs list -t snapshot -Ho name $dest_dataset@$j < /dev/null; then
      old=$j
      break
    fi
  done
  if [ -z "${old+set}" ]; then
    echo "fatal: no bookmark has snapshot on destination: $src_dataset"
    exit 1
  fi
  echo "=== old: $old"
  zfs-sync-snapshots --bookmark --delete this --i-am-a-cron-job-fuck-me-up-and-delete-without-asking --rsh "$rsh" $dest_dataset $src_dataset --incremental-source \#$old $new wet
done
