source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx PATH "$HOME/.local/bin" "$HOME/.npm-global/bin" $PATH

if command -v zoxide >/dev/null
    zoxide init fish | source
end
