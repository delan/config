# Pretend to be an xterm even if we're on a console
export TERM=xterm

# Default Cygwin prompt
# export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '

# Use vim as the default text editor
export VISUAL=vim
export EDITOR=vim

# Force non-login POSIX /bin/sh to execute this file
export ENV=~/.profile

# Set default package mirror for OpenBSD
export PKG_PATH=ftp://ftp.ii.net/pub/OpenBSD/5.5/packages/amd64/
