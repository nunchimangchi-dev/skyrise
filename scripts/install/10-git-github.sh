#!/usr/bin/env bash
# Sets git identity, generates a per-host SSH key, and gets GitHub CLI authenticated.
# gh auth login is interactive (browser OAuth) and is NOT run by this script on purpose --
# credentials/approval must come from the human at the keyboard.
set -euo pipefail

GIT_NAME="nunchimangchi-dev"
GIT_EMAIL="277221692+nunchimangchi-dev@users.noreply.github.com"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "vim"
echo "==> git identity set: $GIT_NAME <$GIT_EMAIL>"

KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  echo "==> Generating SSH key for $(hostname)"
  ssh-keygen -t ed25519 -C "${GIT_NAME}@$(hostname)" -f "$KEY" -N ""
else
  echo "==> SSH key already exists at $KEY, skipping"
fi

if gh auth status >/dev/null 2>&1; then
  echo "==> gh already authenticated."
else
  cat <<EOF

==> Manual step required:
    Run this yourself (needs your browser to approve):

        gh auth login --git-protocol ssh --web

    When it asks to upload your SSH key, choose $KEY.
EOF
fi
