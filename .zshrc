HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

precmd() {
	print -Pn "\e]0;%n@%m %? %~\a"
}

setopt appendhistory autocd beep extendedglob nomatch notify
bindkey -e
zstyle :compinstall filename '/home/delan/.zshrc'
autoload -Uz compinit
compinit

. ~/.profile
