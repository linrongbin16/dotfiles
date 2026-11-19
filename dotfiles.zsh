#!/bin/zsh

# performance
# Stay within the defaults of every platform this file runs on: macOS caps
# `kern.maxfilesperproc` at 10240 and `kern.maxprocperuid` at 2660, so asking
# for more fails and leaves the shell at its defaults.
ulimit -n 10240
ulimit -u 2660

# ls
alias l="eza -lh"
alias ll="eza -alh"

# lazygit
alias lg="lazygit"

# git
alias gs="git status"
alias gp="git pull"
alias gP="git push"
alias ga="git add"
alias gco="git commit"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# go
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

# deno
if [ -f "$HOME/.deno/env" ]; then
  . "$HOME/.deno/env"
fi

# bun
if [ -d "$HOME/.bun/bin" ]; then
  export PATH="$PATH:$HOME/.bun/bin"
fi

# bob-nvim
if [ -d "$HOME/.local/share/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
fi
if [ -d "$HOME/Library/Application Support/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/Library/Application Support/bob/nvim-bin"
fi

# local bins
export PATH="$HOME/.local/bin:$PATH"

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# git-prompt.zsh {{{
if [ -f "$HOME/.zsh/git-prompt.zsh/git-prompt.zsh" ]; then
  source $HOME/.zsh/git-prompt.zsh/git-prompt.zsh
fi

# ZSH_THEME_GIT_PROMPT_PREFIX="["
# ZSH_THEME_GIT_PROMPT_SUFFIX="] "
# ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_SEPARATOR=" "
ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_bold[cyan]%}:"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX="%{$fg[red]%}(%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX="%{$fg[red]%})"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}x"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}o"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[red]%}+"
ZSH_THEME_GIT_PROMPT_BEHIND="↓"
ZSH_THEME_GIT_PROMPT_AHEAD="↑"
ZSH_THEME_GIT_PROMPT_UNTRACKED="…"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✓"
ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%{$fg_bold[yellow]%}⟳"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}⚑"

PROMPT=$'%F{blue}%~%f %b$(gitprompt)%f
%(12V.%F{242}%12v%f .)%(?.%F{cyan}.%F{red})❯%f '

RPROMPT=''
# git-prompt.zsh }}}

# xterm
export TERM="xterm-256color"

# zsh disable vi-mode, enforce emacs-mode
if [[ "$SHELL" == *zsh ]]; then
  bindkey -e
fi
