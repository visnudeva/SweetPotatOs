#!/usr/bin/env bash
# SweetPotato app launcher — .desktop apps only (not full $PATH)
set -euo pipefail

# Colors: charcoal / potato orange selection / white text
DMENU='wmenu -i -f "Noto Sans 11" -p apps -N 1d1f21ff -n f5e6e8ff -M a73b50ff -m ffffffff -S f79b29ff -s 1d1f21ff'

mkdir -p "${HOME}/.cache"

exec j4-dmenu-desktop \
  --dmenu="${DMENU}" \
  --term="foot" \
  --no-generic \
  --usage-log="${HOME}/.cache/sweetpotato-apps.log"
