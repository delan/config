HISTFILE=~/.histfile
HISTSIZE=999999
SAVEHIST=999999

precmd() {
	print -Pn "\e]0;%n@%m %? %~\a"
}

setopt appendhistory autocd beep extendedglob menucomplete nomatch notify

bindkey -e

# Delete/Home/End to work as usual
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

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

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

zstyle :compinstall filename '/home/delan/.zshrc'
autoload -Uz compinit
compinit

# NixOS: interactive
export NIX_AUTO_RUN=1

# if we are an interactive login shell on tty1, startx instead
case "$-" in
(*i*l*)
	case "$(tty)" in
	(*/tty1) exec startx ;;
	esac
	;;
esac
