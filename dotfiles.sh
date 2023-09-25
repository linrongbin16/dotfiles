#!/bin/bash

# performance
ulimit -n 200000
ulimit -u 2048

# ls
if [ -x "$(command -v eza)" ]; then
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
alias ga="git add"
alias gc="git commit"
alias gck="git checkout"
alias gb="git branch"
alias gm="git merge"

# path
export PATH="$PATH:$HOME/.dotfiles/bin"
