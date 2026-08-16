#!/usr/bin/env bash
# Installs the core toolchain: git, GitHub CLI, tmux, fish, fisher, bitwarden-cli, chezmoi.
# Safe to re-run.
set -euo pipefail

if command -v pacman >/dev/null 2>&1; then
  echo "==> Arch/CachyOS: installing via pacman (needs sudo)"
  sudo pacman -S --needed git github-cli tmux fish fisher bitwarden-cli chezmoi
elif command -v brew >/dev/null 2>&1; then
  echo "==> macOS: installing via Homebrew"
  brew install git gh tmux fish bitwarden-cli chezmoi
  # fisher is installed as a fish plugin below, not a brew formula
else
  echo "No supported package manager found (expected pacman or brew)." >&2
  exit 1
fi

if ! fish -c 'functions -q fisher' >/dev/null 2>&1; then
  echo "==> Installing fisher (fish plugin manager)"
  fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fi

echo "==> Packages ready."
