#!/usr/bin/env zsh
set -eu
action=${1-all}

trace() {
	printf >&2 \%s\\n "$(
		printf \%s "$1"
		shift
		printf ' %s' "$@"
	)"
	"$@"
}

# action <keyword,...> <command> [arg ...]
action() {
	case ",$1," in
	*,$action,*)
		shift
		"$@"
		;;
	esac
}

# root_with_acl <path> <acl,...>
# Makes <path> and all of its descendants owned by root:root, and replaces their
# default and access ACL with the given <acl,...>.
root_with_acl() {
	set -- "$1" "$2" "$(printf \%s "$2" | sed -E 's/^/d:/;s/,/,d:/g')"
	trace chown -R root:root -- "$1"
	trace setfacl -Rn --set "$2,$3" -- "$1"
}

# public <path> <acl,...>
public() {
	root_with_acl "$1" "u::rwX,g::rX,o::rX,m::rwX,$2"
}

# private <path> <acl,...>
private() {
	root_with_acl "$1" "u::rwX,g::0,o::0,m::rwX,$2"
}

action all echo 'fixing all perms' >&2

action all,active trace chown root:root /ocean/active /ocean/active/services
action all,active trace chown -R root:root /ocean/active/{2023,plex,retro}
action all,active,scanner private /ocean/active/scanner scanner:7,delan:7,aria:7,lucatiel:7,the6p4c:7
action all,active,torrents public /ocean/active/torrents qbittorrent:7,delan:7,aria:7,the6p4c:7,hannah:7,sonarr:7,radarr:7
action all,active,sonarr public /ocean/active/sonarr sonarr:7,bazarr:7,delan:7,aria:7,the6p4c:7,hannah:7
action all,active,radarr public /ocean/active/radarr radarr:7,bazarr:7,delan:7,aria:7,the6p4c:7,hannah:7

action all,private trace chown root:root /ocean/private
action all,private trace chown -R root:root /ocean/private/2023
action all,private,delanria private /ocean/private/delanria delan:7,aria:7
action all,private,shouse private /ocean/private/shouse delan:7,aria:7,lucatiel:7,the6p4c:7

action all,public public /ocean/public delan:7,aria:7,the6p4c:7,hannah:7
