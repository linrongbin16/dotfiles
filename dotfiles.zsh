#!/bin/zsh

OS="$(uname -s)"
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
  export GOROOT="$HOME/.go" # where go is installed
  export PATH="$PATH:$GOROOT/bin"
fi
export GOPATH="$HOME/go"  # user workspace
export PATH="$PATH:$GOPATH/bin"

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

# pure
init_pure_prompt() {
  fpath+=($HOME/.zsh/pure)
  autoload -U promptinit; promptinit
  zstyle :prompt:pure:prompt:success color green
  zstyle :prompt:pure:git:stash show yes
  prompt pure
}

# agkozak
init_agkozak_prompt() {
  source ~/.zsh/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh
}

if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  # init_pure_prompt
  init_agkozak_prompt
fi
