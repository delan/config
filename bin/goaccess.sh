#!/usr/bin/env zsh
# usage: goaccess.sh [--ssh=<ssh host>] [--vhost=<virtual host>]
set -euo pipefail
file_key=goaccess
# digest and remove (`shift`) the incoming args, replacing them with any args
# that need to be relayed with `--ssh=` (`set -- "$@" "$arg"`).
for arg in "$@"; do
    shift
    case "$arg" in
    (--ssh=*)
        ssh_host=${arg#--ssh=}
        exec ssh -tL 7890:127.0.0.1:7890 "$ssh_host" goaccess.sh "$@"
        ;;
    (--vhost=*)
        file_key=goaccess_host_"${arg#--vhost=}"
        set -- "$@" "$arg"
        ;;
    esac
done
>&2 echo ">>> https://bucket.daz.cat/private/$file_key.html"
exec goaccess "/var/log/nginx/$file_key.log" --log-format=VCOMBINED \
    --output="/var/www/bucket.daz.cat/private/$file_key.html" --real-time-html --ws-url=ws://127.0.0.1:7890
