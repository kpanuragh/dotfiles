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

export TERM=xterm-256color
alias lms="cd /home/anuragh/Projects/oelms9/docker && docker compose up -d && cd ../"
alias lms_cb="cd /home/anuragh/Projects/oelms9 && nodemon --exec 'docker exec -t oelms-app php src/crons/combine.php' -e js --ignore src/public"

alias emacs="emacs -nw"

export PATH=$PATH:$HOME/.local/bin

function gcm() {
  commit_message=$(git diff --staged | sgpt "Generate git commit message using Use the body to explain what and why you have done something. In most cases, you can leave out details about how a change has been made.no extra description just give commit message only, for my changes in")
  git commit -m "$commit_message"
}
export PATH="$HOME/.emacs.d/bin:/home/anuragh/go/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
eval "$(starship init bash)"

. "$HOME/.cargo/env"

# Shell-GPT integration BASH v0.2
_sgpt_bash() {
  if [[ -n "$READLINE_LINE" ]]; then
    READLINE_LINE=$(sgpt --shell --no-interaction <<<"$READLINE_LINE")
    READLINE_POINT=${#READLINE_LINE}
  fi
}
bind -x '"\C-l": _sgpt_bash'
# Shell-GPT integration BASH v0.2
