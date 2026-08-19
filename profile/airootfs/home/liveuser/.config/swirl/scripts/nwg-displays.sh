#!/usr/bin/env bash
# Launch nwg-displays on Swirl: needs SWAYSOCK + ~/.config/sway (not shipped in skel).
set -euo pipefail

find_swaysock() {
  local rt s
  if [[ -n "${SWAYSOCK:-}" && -S "${SWAYSOCK}" ]]; then
    return 0
  fi
  rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  s="$(find "${rt}" -maxdepth 1 \( -name 'sway-ipc.*.sock' -o -name 'swirl-ipc.*.sock' \) -type s 2>/dev/null | head -1 || true)"
  if [[ -z "${s}" ]] && command -v swirl >/dev/null 2>&1; then
    s="$(swirl --get-socketpath 2>/dev/null || true)"
  fi
  if [[ -z "${s}" ]] && command -v sway >/dev/null 2>&1; then
    s="$(sway --get-socketpath 2>/dev/null || true)"
  fi
  [[ -n "${s}" && -S "${s}" ]] || return 1
  export SWAYSOCK="${s}"
}

if ! find_swaysock; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical "Displays" "Could not find Swirl. Open Displays from a Swirl session."
  fi
  exit 1
fi

mkdir -p "${HOME}/.config/sway"
exec nwg-displays "$@"
