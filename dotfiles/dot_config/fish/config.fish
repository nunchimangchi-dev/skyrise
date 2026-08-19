if command -v starship >/dev/null
    starship init fish | source
end

if command -v zoxide >/dev/null
    zoxide init fish | source
end

set -gx PATH "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.npm-global/bin" $PATH

# Man pages rendered through bat, matches the eza/bat-forward look everywhere else
if command -v bat >/dev/null
    set -x MANROFFOPT "-c"
    set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

# Modern `ls` family - same flags as the old CachyOS defaults, so this looks identical
if command -v eza >/dev/null
    alias ls 'eza -al --color=always --group-directories-first --icons=always'
    alias la 'eza -a --color=always --group-directories-first --icons=always'
    alias ll 'eza -l --color=always --group-directories-first --icons=always'
    alias lt 'eza -aT --color=always --group-directories-first --icons=always'
    alias l. "eza -a | grep -e '^\.'"
end

# Git shortcuts
alias gst 'git status'
alias gd 'git diff'
alias gl 'git log --oneline --graph --decorate'
alias gco 'git checkout'

# Navigation
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

# Color by default
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'

# Fish command history, with timestamps
function history
    builtin history --show-time='%F %T ' $argv
end

# !! and !$ (bash/zsh-style history expansion) - https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Host-local, untracked overrides (e.g. box's Arch-only aliases) live here, not in chezmoi
if test -f ~/.fish_profile
    source ~/.fish_profile
end
