#!/usr/bin/env bash
# Persist the current monitor layout to ~/.config/sway/outputs (survives reboot).
# Use after wlr-randr changes, or when nwg-displays did not write the file.
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

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "$@" || true
}

if ! find_swaysock; then
  notify -u critical "Display layout" "Could not find Swirl (not in a session?)."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  notify -u critical "Display layout" "jq is required to save the layout."
  exit 1
fi

mkdir -p "${HOME}/.config/sway"
out="${HOME}/.config/sway/outputs"
tmp="$(mktemp)"

swaymsg -t get_outputs | jq -r '
  .[] | select(.active) |
  (if .current_mode.refresh then (.current_mode.refresh / 1000 | round) else 60 end) as $hz |
  "output \(.name) mode \(.current_mode.width)x\(.current_mode.height)@\($hz) position \(.rect.x),\(.rect.y) scale \(.scale)"
' >"${tmp}"

if [[ ! -s "${tmp}" ]]; then
  rm -f "${tmp}"
  notify -u critical "Display layout" "No active outputs to save."
  exit 1
fi

mv -f "${tmp}" "${out}"
swaymsg source "${out}" 2>/dev/null || true
"${HOME}/.config/swirl/scripts/sync-kanshi-from-outputs.sh" 2>/dev/null || true

if command -v kanshictl >/dev/null 2>&1; then
  kanshictl reload 2>/dev/null || true
fi

notify "Display layout saved" "Settings will apply again after reboot."
