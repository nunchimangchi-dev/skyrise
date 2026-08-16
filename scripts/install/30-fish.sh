#!/usr/bin/env bash
# Makes fish the default login shell and syncs fisher plugins.
# Requires dotfiles to already be applied so ~/.config/fish/fish_plugins exists.
set -euo pipefail

FISH_PATH="$(command -v fish)"

if ! grep -qx "$FISH_PATH" /etc/shells; then
  echo "==> Adding $FISH_PATH to /etc/shells (needs sudo)"
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
  echo "==> Setting fish as default shell (needs sudo, or your password)"
  chsh -s "$FISH_PATH"
else
  echo "==> fish is already the default shell"
fi

echo "==> Syncing fisher plugins from fish_plugins"
fish -c 'fisher update'

echo "==> fish ready. Log out and back in for the default shell change to apply."
