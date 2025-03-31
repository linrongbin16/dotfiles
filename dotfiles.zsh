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

# git
alias gs="git status"
alias gp="git pull"
alias gP="git push"
alias ga="git add"
alias gb="git branch"
alias gm="git merge"
alias gc="git commit"

# dotfiles
export PATH="$PATH:$HOME/.dotfiles/bin"

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
eval "$(atuin init zsh)"

# mise
eval "$(~/.local/bin/mise activate zsh)"

# pure
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
zstyle :prompt:pure:prompt:success color green
zstyle :prompt:pure:git:stash show yes
prompt pure

# fzf-tab
autoload -U compinit; compinit
source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd/z
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
