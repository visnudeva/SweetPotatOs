#!/usr/bin/env bash
# SweetPotato app launcher — .desktop apps only (not full $PATH)
set -euo pipefail

# Colors come from the active theme. Sweet potato is the fallback.
ACTIVE="${HOME}/.config/sweetpotatos/active.sh"
if [[ -f "${ACTIVE}" ]]; then
  # shellcheck disable=SC1090
  source "${ACTIVE}"
fi
: "${SPO_SURFACE:=1d1f21}"
: "${SPO_TEXT:=f5e6e8}"
: "${SPO_ACCENT:=a73b50}"
: "${SPO_ON_ACCENT:=ffffff}"
: "${SPO_HIGHLIGHT:=f79b29}"
: "${SPO_ON_HIGHLIGHT:=1d1f21}"
DMENU="wmenu -i -f \"Noto Sans 11\" -p apps -N ${SPO_SURFACE}ff -n ${SPO_TEXT}ff -M ${SPO_ACCENT}ff -m ${SPO_ON_ACCENT}ff -S ${SPO_HIGHLIGHT}ff -s ${SPO_ON_HIGHLIGHT}ff"

mkdir -p "${HOME}/.cache"

exec j4-dmenu-desktop \
  --dmenu="${DMENU}" \
  --term="foot" \
  --no-generic \
  --usage-log="${HOME}/.cache/sweetpotato-apps.log"
