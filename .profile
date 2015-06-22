# Use emacs line editing
set -o emacs

# Language and encoding
export LANG=en_AU.UTF-8

# Executable search path
export PATH="$HOME/bin"
export PATH="$PATH:/usr/local/texlive/2014/bin/universal-darwin"
export PATH="$PATH:/usr/local/bin:/usr/local/sbin"
export PATH="$PATH:/usr/bin:/usr/sbin"
export PATH="$PATH:/usr/X11R6/bin:/usr/games"
export PATH="$PATH:/bin:/sbin"
export PATH="$PATH:."

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

# Fire up gpg-agent if it's not already running
gpg_agent_env="$HOME/.gnupg/gpg-agent.env"
if [ -e "$gpg_agent_env" ] && kill -0 $(
	grep GPG_AGENT_INFO "$gpg_agent_env" | cut -d ':' -f 2
) 2>/dev/null; then
	eval "$(cat "$gpg_agent_env")"
else
	eval "$(
		gpg-agent --daemon --enable-ssh-support \
			--write-env-file "$gpg_agent_env"
	)"
fi
export GPG_AGENT_INFO  # the env file does not contain the export statement
export SSH_AUTH_SOCK   # enable gpg-agent for ssh
