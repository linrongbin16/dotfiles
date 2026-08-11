#!/bin/zsh

# performance
ulimit -n 200000
ulimit -u 2048

# ls
alias l="eza -lh"
alias ll="eza -alh"

# lazygit
alias lg="lazygit"

# fzf
if [ -x "$HOME/.fzf/bin" ]; then
  export PATH="$PATH:$HOME/.fzf/bin"
fi

# git
alias gs="git status"
alias gpl="git pull"
alias gps="git push"
alias ga="git add"
alias gco="git commit"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# go
if [ -x "$HOME/.go/bin/go" ]; then
  export PATH="$PATH:$HOME/.go/bin"
fi
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

# deno
if [ -f "$HOME/.deno/env" ]; then
  . "$HOME/.deno/env"
fi

# bun
if [ -x "$HOME/.bun/bin" ]; then
  export PATH="$PATH:$HOME/.bun/bin"
fi

# bob-nvim
if [ -d "$HOME/.local/share/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
fi

# local bins
export PATH="$PATH:$HOME/.local/bin"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# atuin
if [ -f "$HOME/.atuin/bin/env" ]; then
  . "$HOME/.atuin/bin/env"
fi
eval "$(atuin init zsh)"

# mise
eval "$(~/.local/bin/mise activate zsh)"

# git-prompt.zsh {{{
source ~/.zsh/git-prompt.zsh/git-prompt.zsh

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
