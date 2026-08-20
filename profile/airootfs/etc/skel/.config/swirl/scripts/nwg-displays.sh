#!/usr/bin/env bash
# Launch nwg-displays on Swirl and sync saved layout into kanshi afterward.
set -euo pipefail

# App-launcher children sometimes drop session vars; recover them.
if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  for cand in wayland-1 wayland-0; do
    if [[ -S "${XDG_RUNTIME_DIR}/${cand}" ]]; then
      export WAYLAND_DISPLAY="${cand}"
      break
    fi
  done
fi

find_swaysock() {
  local rt s
  if [[ -n "${SWAYSOCK:-}" && -S "${SWAYSOCK}" ]]; then
    return 0
  fi
  if [[ -n "${I3SOCK:-}" && -S "${I3SOCK}" ]]; then
    export SWAYSOCK="${I3SOCK}"
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
    notify-send -u critical -t 8000 "Displays" "Could not find Swirl IPC. Try Mod+Shift+d or run: nwg-displays"
  fi
  exit 1
fi

mkdir -p "${HOME}/.config/sway"
touch "${HOME}/.config/sway/outputs" "${HOME}/.config/sway/workspaces"

# Same binary as `nwg-displays` in a terminal — wrapper only fixes env + kanshi sync.
exec_nwg() {
  command -v nwg-displays >/dev/null 2>&1 || {
    notify-send -u critical -t 8000 "Displays" "nwg-displays is not installed." 2>/dev/null || true
    exit 1
  }
  nwg-displays "$@"
}

exec_nwg "$@"

if [[ -s "${HOME}/.config/sway/outputs" ]]; then
  swaymsg source "${HOME}/.config/sway/outputs" 2>/dev/null || true
  "${HOME}/.config/swirl/scripts/sync-kanshi-from-outputs.sh" 2>/dev/null || true
  command -v kanshictl >/dev/null 2>&1 && kanshictl reload 2>/dev/null || true
fi
