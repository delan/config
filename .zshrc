HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

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

alias   ls='/bin/ls'
alias   sl='/bin/ls'
alias    a='/bin/ls -a'
alias   la='/bin/ls -a'
alias   al='/bin/ls -a'
alias    l='/bin/ls -la'
alias   ll='/bin/ls -la'
alias naon='nano'
alias path='echo $PATH'
alias lz='. ~/.zshrc'
alias ez='nano ~/.zshrc'
alias mount='sudo mount'
alias umount='sudo umount'
alias systemctl='sudo systemctl'
alias dpkg='sudo dpkg'
alias apt='sudo apt'
alias get='sudo apt-get'
alias cache='sudo apt-cache'
alias show='sudo apt-cache show'
alias policy='sudo apt-cache policy'

. ~/.profile
