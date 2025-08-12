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
export PATH=$PATH:~/.fzf/bin

# git
alias gs="git status"
alias gp="git pull"
alias gP="git push"
alias ga="git add"
alias gb="git branch"
alias gm="git merge"
alias gc="git commit"

# go
if [ -x "$HOME/.go/bin/go" ]; then
  export GOROOT="$HOME/.go" # where go is installed
  export PATH="$PATH:$GOROOT/bin"
fi
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

# deno/bun
if [ -x "$HOME/.deno/bin/deno" ]; then
  export PATH="$PATH:$HOME/.deno/bin"
fi
if [ -d "$HOME/.bun/bin/bun" ]; then
  export PATH="$PATH:$HOME/.bun/bin"
fi

# neovim
if [ -d "$HOME/.local/share/bob/nvim-bin" ]; then
  export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
fi

# pipx
export PATH="$PATH:$HOME/.local/bin"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# atuin
if [ -f "$HOME/.atuin/bin/env" ]; then
  . "$HOME/.atuin/bin/env"
fi
if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  eval "$(atuin init zsh)"
else
  eval "$(atuin init --disable-ctrl-r --disable-up-arrow zsh)"
fi

# mise
eval "$(~/.local/bin/mise activate zsh)"

if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  if [ ! -n "$GHOSTTY_RESOURCES_DIR" ]; then
    AGKOZAK_CUSTOM_SYMBOLS=( '⇣⇡' '⇣' '⇡' '+' 'x' '!' '>' '?' 'S')
  fi
  # agkozak prompt
  AGKOZAK_PROMPT_DIRTRIM=0
  AGKOZAK_LEFT_PROMPT_ONLY=1
  AGKOZAK_PROMPT_CHAR=( '%F{magenta}❯%f' %# : )
  source ~/.zsh/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh
fi
