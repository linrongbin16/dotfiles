#!/bin/bash

# performance
ulimit -n 200000
ulimit -u 2048

# ls
if [ -x "$(command -v lsd)" ]; then
	alias l="lsd -lh --header --icon=never"
	alias ll="lsd -alh --header --icon=never"
elif [ -x "$(command -v eza)" ]; then
	alias l="eza -lh"
	alias ll="eza -alh"
elif [ -x "$(command -v exa)" ]; then
	alias l="exa -lh"
	alias ll="exa -alh"
else
	alias l="ls -lh"
	alias ll="ls -alh"
fi

# lazygit
alias lg="lazygit"

# git
alias gs="git status"
alias gp="git pull"
alias gP="git push"
alias gps="git push"
alias gf="git fetch"
alias ga="git add"
alias gb="git branch"
alias gm="git merge"
alias gcm="git commit"
alias gck="git checkout"
alias gcf="git config"

# path
export PATH="$PATH:$HOME/.dotfiles/bin"

# pure zsh theme
fpath+=($HOME/.zsh/pure)
zstyle :prompt:pure:git:branch color 'magenta'
zstyle :prompt:pure:git:branch:cached color 'magenta'
zstyle :prompt:pure:prompt:success color 'green'
autoload -U promptinit
promptinit
prompt pure
