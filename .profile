# Use emacs line editing
set -o emacs

# Default OpenBSD PATH variable
export PATH=$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:/usr/local/sbin:/usr/games:.

if ps -p $$ | egrep -q '[ (/]sh'; then
	green="$(printf '\e[32m')"
	normal="$(printf '\e[m')"
	title="$(printf '\e]0;')"
	end="$(printf '\a')"
	text="$(whoami)@$(hostname -s)"
	sigil="$([ "|$(id -u)|" = '|0|' ] && echo '#' || echo '$')"
	export PS1="$title$text$end$green$text$normal $sigil "
else
	export PS1='\[\e]0;\u@\h $? \w\a\]'
	export PS1="$PS1"'\[\e[32m\]\u@\h '
	export PS1="$PS1"'\[\e[35m\]$? '
	export PS1="$PS1"'\[\e[33m\]\w '
	export PS1="$PS1"'\[\e[m\]\$ '
fi
export PROMPT='%F{2}%n@%m %F{5}%? %F{3}%~ %f%% '

# Use vim as the default text editor
export VISUAL=vim
export EDITOR=vim

# Force non-login POSIX /bin/sh to execute this file
export ENV=~/.profile

# Set default package mirror for OpenBSD
export PKG_PATH=ftp://ftp.ii.net/pub/OpenBSD/$(uname -r)/packages/$(uname -m)/

# Cajole X11 applications who prefer .Xdefaults into using .Xresources
export XENVIRONMENT=$HOME/.Xresources
