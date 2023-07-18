#!/bin/bash

# performance
ulimit -n 200000
ulimit -u 2048

# mzpt prompt theme
[ -f ~/.mzpt/mzpt.zsh ] && source ~/.mzpt/mzpt.zsh

# ls
alias l="exa -lh"
alias ll="exa -alh"

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
