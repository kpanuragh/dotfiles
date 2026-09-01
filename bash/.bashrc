export PATH="/home/anuragh/.nvm/versions/node/v24.16.0/bin:$PATH"
# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]]; then
  # Shell is non-interactive.  Be done now!
  return
fi

# Put your fun stuff here.
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# greetd/tuigreet doesn't wrap Hyprland in dbus-run-session, so DBUS_SESSION_BUS_ADDRESS
# doesn't propagate to new terminals. Scoop it from the running Hyprland process.
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  for _p in $(pgrep -u "$USER" -x 'mako|waybar|Hyprland' 2>/dev/null); do
    if [ -r "/proc/$_p/environ" ]; then
      _a=$(tr '\0' '\n' <"/proc/$_p/environ" 2>/dev/null | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -1)
      [ -n "$_a" ] && export DBUS_SESSION_BUS_ADDRESS="$_a" && break
    fi
  done
  unset _p _a
fi
alias lim_claude='CLAUDE_CONFIG_DIR=~/.vieroots_claude claude'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# fzf — fuzzy finder
# Ctrl-R: history search, Ctrl-T: file picker, Alt-C: cd into subdir
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
fi

# ─── Shell behaviour ─────────────────────────────────────────────
shopt -s histappend checkwinsize autocd cdspell dirspell globstar nocaseglob
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
HISTIGNORE='ls:ll:cd:cd ..:..:...:exit:clear:history'
PROMPT_DIRTRIM=3
export EDITOR=nvim VISUAL=nvim PAGER=less LESS='-R -F -X -i'

# ─── Prompt (Catppuccin Mocha, git-aware, two lines) ─────────────
__git_branch() {
  local b
  b=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
    b=$(git rev-parse --short HEAD 2>/dev/null) ||
    return
  [ -n "$b" ] && printf ' %s' "$b"
}
__set_prompt() {
  local rc=$?
  local m='\[\e[38;5;141m\]' s='\[\e[38;5;117m\]' y='\[\e[38;5;222m\]'
  local r='\[\e[38;5;210m\]' g='\[\e[38;5;114m\]' x='\[\e[0m\]'
  local sigil="${g}❯${x}"
  [ $rc -ne 0 ] && sigil="${r}❯${x}"
  [ $EUID -eq 0 ] && sigil="${r}#${x}"
  PS1="${m}\u@\h${x} ${s}\w${x}${y}$(__git_branch)${x}\n${sigil} "
}
PROMPT_COMMAND=__set_prompt

# ─── Aliases ─────────────────────────────────────────────────────
alias ls='ls --color=auto -h --group-directories-first'
alias ll='ls -lA'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias e='${EDITOR}'
alias :q='exit'
mkcd() { mkdir -p "$1" && cd "$1"; }

# ─── Kitty + SSH: copy terminfo so remote sees a known terminal ──
if [ "$TERM" = "xterm-kitty" ] && command -v kitten >/dev/null 2>&1; then
  alias ssh='kitten ssh'
fi

# Added by LM Studio CLI tool (lms)
export PATH="/home/anuragh/.lmstudio/bin:$PATH"

# Doom Emacs
export PATH="$HOME/.config/emacs/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/anuragh/.local/bin:$PATH"

# OpenClaw Completion
[ -f "/home/anuragh/.openclaw/completions/openclaw.bash" ] && source "/home/anuragh/.openclaw/completions/openclaw.bash"

# ─── Hacker aesthetic (green matrix rice) — remove this line to revert ───
[ -f "$HOME/.config/hacker-rice.sh" ] && source "$HOME/.config/hacker-rice.sh"

# rustup (0xOS: must shadow Gentoo rust-bin, which lacks nightly and rust-src)
export PATH="$HOME/.cargo/bin:$PATH"
