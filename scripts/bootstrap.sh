#!/usr/bin/env bash
# Entry point for setting up a new dev host. Run from the repo root:
#   ./scripts/bootstrap.sh
#
# Each script in install/ is idempotent (safe to re-run) and is added here
# as that phase of the skyrise project is built and verified -- see the
# dashboard (dashboard/) or README for current status.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

./scripts/install/00-packages.sh
./scripts/install/10-git-github.sh

echo
echo "==> Bootstrap steps run so far. Check the dashboard or README for what's next."
