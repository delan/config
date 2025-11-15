#!/usr/bin/env zsh
set -euo shwordsplit -o pipefail

webhook=${BUSTED_WEBHOOK-$(cat /run/secrets/BUSTED_WEBHOOK)}
hostname=$(hostname | sed 's/[.].*//')
log=sync-$hostname-$(date -u +\%FT\%RZ).log
cd ~

# to upload an attachment from local file (not from remote URL), we need `--upload-file` (PUT),
# but this means we can’t use `--data` (request body) for the message text. thankfully we can use
# the ‘X-Message’ header instead, but newlines etc need to be escaped using the RFC 2047 syntax.
# i did consider just sending the file in a separate notification, but where’s the fun in that?
if sync-$hostname.sh 2>&1 | tee $log; then
  curl \
    -H "X-Priority: 1" \
    -H "X-Title: sync $hostname ok" \
    -H "X-Message: =?UTF-8?B?$(< $log tail -3 | tail -c 2000 | base64 -w 0)?=" \
    -T $log -H "X-Filename: sync $hostname ok.txt" \
    "$webhook"
else
  curl \
    -H "X-Priority: 3" \
    -H "X-Title: sync $hostname FAILED" \
    -H "X-Message: =?UTF-8?B?$(< $log tail -3 | tail -c 2000 | base64 -w 0)?=" \
    -T $log -H "X-Filename: sync $hostname FAILED.txt" \
    "$webhook"
fi
