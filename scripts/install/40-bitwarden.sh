#!/usr/bin/env bash
# Bitwarden CLI setup check. Login and unlock are deliberately NOT scripted --
# both need your master password typed by you, never stored or passed by a script.
set -euo pipefail

if ! command -v bw >/dev/null 2>&1; then
  echo "bw not found - run 00-packages.sh first" >&2
  exit 1
fi

STATUS="$(bw status | python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])')"

case "$STATUS" in
  unauthenticated)
    cat <<EOF
==> Manual step required:
    bw login
    (asks for your email + master password)
EOF
    ;;
  locked)
    echo "==> Logged in, vault is locked (this is the correct resting state)."
    echo "    To use it in a shell session: export BW_SESSION=\$(bw unlock --raw)"
    ;;
  unlocked)
    echo "==> Vault already unlocked in this session."
    ;;
esac
