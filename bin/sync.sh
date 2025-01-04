#!/usr/bin/env zsh
set -euo shwordsplit -o pipefail

webhook=${BUSTED_WEBHOOK-$(cat /run/secrets/BUSTED_WEBHOOK)}
hostname=$(hostname | sed 's/[.].*//')
log=sync-$hostname-$(date -u +\%FT\%RZ).log
cd ~

if ~delan/bin/sync-$hostname.sh 2>&1 | tee $log; then
  curl -F 'files[n]'="@$log" -F content="sync $hostname ok" "$webhook"
else
  curl -F 'files[n]'="@$log" -F content="sync $hostname failed! @everyone" "$webhook"
fi
