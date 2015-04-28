HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

precmd() {
	print -Pn "\e]0;%n@%m %? %~\a"
}

setopt appendhistory autocd beep extendedglob nomatch notify

bindkey -e

# Ctrl+Left/Right to move by whole words
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Ctrl+Backspace/Delete to delete whole words
bindkey '^[[3;5~' kill-word
bindkey '^_' backward-kill-word

# Ctrl+Shift+Backspace/Delete to delete to start/end of the line
bindkey '^[[3;6~' kill-line
bindkey '\xC2\x9F' backward-kill-line

# Alt-Backspace for undo
bindkey '^[^?' undo

# Ctrl+Up/Down for searching command history
bindkey '^[[1;5A' history-search-backward
bindkey '^[[1;5B' history-search-forward

zstyle :compinstall filename '/home/delan/.zshrc'
autoload -Uz compinit
compinit

. ~/.profile
