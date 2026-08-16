#!/usr/bin/env bash
# Installs TPM (tmux plugin manager) and the plugins listed in tmux.conf.
# Requires dotfiles to already be applied (chezmoi) so ~/.config/tmux/tmux.conf exists.
set -euo pipefail

TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "==> Cloning tpm"
  git clone -q https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "==> tpm already present"
fi

echo "==> Installing tmux plugins headlessly"
"$TPM_DIR/bin/install_plugins"

echo "==> tmux ready. Inside a session, prefix + U updates plugins."
