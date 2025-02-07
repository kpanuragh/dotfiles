set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "eza --icons"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias cat "bat"
alias grep "rg"
alias find "fd"
alias du "dust"
alias ps "procs"
alias top "btm"
alias ping "prettyping"
alias traceroute "mtr"
alias nslookup "dog"
alias tar "tar --use-compress-program=zstd"
alias g git
command -qv nvim && alias vim nvim
alias lms "cd /home/anuragh/Projects/oelms9/docker; docker compose up -d; cd ../"
alias lms_cb "cd /home/anuragh/Projects/oelms9; nodemon --exec 'docker exec -t oelms-app php src/crons/combine.php'  -e js --ignore src/public"
alias lms_ug "docker exec -t oelms-app php src/crons/upgrade.php"
alias emacs "emacs -nw"




set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

set -gx PATH $PATH $HOME/.local/bin
set -gx PATH $HOME/.emacs.d/bin $PATH

# Rust
set -gx PATH $HOME/.cargo/bin $PATH

# Git commit function using Shell-GPT
function gcm
    set commit_message (git diff --staged | sgpt "Generate git commit message using the body to explain what changed.")
    git commit -m "$commit_message"
end



# Load Cargo environment

# Shell-GPT integration for Fish
function _sgpt_fish
    if test -n (commandline)
        set output (commandline | sgpt --shell --no-interaction)
        commandline -r "$output"
    end
end

bind \cl _sgpt_fish

if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end
