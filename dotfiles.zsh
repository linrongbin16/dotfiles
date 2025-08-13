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
  source ~/.zsh/git-prompt.zsh/git-prompt.zsh

  ZSH_THEME_GIT_PROMPT_PREFIX="["
  ZSH_THEME_GIT_PROMPT_SUFFIX="] "
  ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
  ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_bold[cyan]%}:"
  ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX="%{$fg[red]%}(%{$fg[yellow]%}"
  ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX="%{$fg[red]%})"

  # ghostty doesn't support nerd fonts or unicode
  if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
    # ascii text
    ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%{$fg_bold[yellow]%}^"
    ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[red]%}v"
    ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[green]%}^"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}x"
    ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}o"
    ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[red]%}+"
    ZSH_THEME_GIT_PROMPT_UNTRACKED=".."
    ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}$"
    ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}>"
  else
    # nerd fonts and unicode
    ZSH_THEME_GIT_PROMPT_UPSTREAM_SYMBOL="%{$fg_bold[yellow]%}⟳ "
    ZSH_THEME_GIT_PROMPT_BEHIND="↓"
    ZSH_THEME_GIT_PROMPT_AHEAD="↑"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[red]%}✖"
    ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}●"
    ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[red]%}✚"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="…"
    ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}⚑"
    ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}✔"
  fi

  PROMPT=$'%F{blue}%~%f %F{242}$(gitprompt)%f
%(12V.%F{242}%12v%f .)%(?.%F{magenta}.%F{red})❯%f '

  RPROMPT=''
fi
