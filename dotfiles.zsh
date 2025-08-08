#!/bin/zsh

OS="$(uname -s)"

IS_LINUX=0
IS_MAC=0
IS_FREEBSD=0
IS_NETBSD=0
IS_OPENBSD=0
case "$OS" in
Linux)
  IS_LINUX=1
  ;;
FreeBSD)
  IS_FREEBSD=1
  ;;
NetBSD)
  IS_NETBSD=1
  ;;
OpenBSD)
  IS_OPENBSD=1
  ;;
Darwin)
  IS_MAC=1
  ;;
*)
  # Nothing
  ;;
esac

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

# golang
if [ "$IS_MAC" != "1" ]; then
  if [ -d "$HOME/.go/bin" ]; then
    export GOROOT="$HOME/.go" # where go is installed
    export PATH="$PATH:$GOROOT/bin"
  fi
fi
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

# deno/bun
if [ "$IS_MAC" != "1" ]; then
  if [ -d "$HOME/.deno/bin" ]; then
    export PATH="$PATH:$HOME/.deno/bin"
  fi
  if [ -d "$HOME/.bun/bin" ]; then
    export PATH="$PATH:$HOME/.bun/bin"
  fi
fi

# trash
if [ "$IS_MAC" != "1" ]; then
  if [ -x "/opt/homebrew/opt/trash/bin/trash" ]; then
    export PATH="/opt/homebrew/opt/trash/bin:$PATH"
  fi
fi

# neovim
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# atuin
if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  eval "$(atuin init zsh)"
else
  eval "$(atuin init --disable-ctrl-r --disable-up-arrow zsh)"
fi

# mise
eval "$(~/.local/bin/mise activate zsh)"

# agkozak prompt
init_prompt() {
  AGKOZAK_PROMPT_DIRTRIM=0
  AGKOZAK_LEFT_PROMPT_ONLY=1
  # AGKOZAK_CUSTOM_SYMBOLS=( '⇣⇡' '⇣' '⇡' '+' 'x' '!' '>' '?' 'S')
  AGKOZAK_PROMPT_CHAR=( '%F{magenta}❯%f' %# : )
  source ~/.zsh/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh
}

if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  init_prompt
fi
