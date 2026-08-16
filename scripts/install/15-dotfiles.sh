#!/usr/bin/env bash
# Points chezmoi at this repo's dotfiles/ and applies them.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
REPO_ROOT="$(pwd)"

mkdir -p "$HOME/.local/share"

if [ -e "$HOME/.local/share/chezmoi" ] && [ ! -L "$HOME/.local/share/chezmoi" ]; then
  echo "REFUSING: ~/.local/share/chezmoi exists and is not a symlink - resolve manually" >&2
  exit 1
fi

ln -sfn "$REPO_ROOT/dotfiles" "$HOME/.local/share/chezmoi"
echo "==> chezmoi source -> $REPO_ROOT/dotfiles"

echo "==> chezmoi diff:"
chezmoi diff || true

chezmoi apply
echo "==> Applied."
