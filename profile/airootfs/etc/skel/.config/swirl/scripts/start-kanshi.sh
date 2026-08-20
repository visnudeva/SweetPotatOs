#!/usr/bin/env bash
# Start kanshi with profiles synced from the saved sway outputs file.
set -euo pipefail

command -v kanshi >/dev/null 2>&1 || exit 0

"${HOME}/.config/swirl/scripts/sync-kanshi-from-outputs.sh"
exec kanshi
