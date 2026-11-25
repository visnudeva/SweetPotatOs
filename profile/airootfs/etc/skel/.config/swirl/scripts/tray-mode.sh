#!/usr/bin/env bash
# Light tray only: no GTK tray applets; BT + mounts show as text in status.sh.
# State: ~/.config/sweetpotatos/tray-mode — always "text" (icons mode removed).
# Usage: tray-mode.sh [apply|text|status|icons|toggle]
#   icons|toggle are accepted for old callers but still apply light tray.
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/tray-mode"

running() {
  pgrep -x "$1" >/dev/null 2>&1
}

start_bg() {
  local bin="$1"
  shift
  command -v "${bin}" >/dev/null 2>&1 || return 0
  if running "${bin}"; then
    return 0
  fi
  "${bin}" "$@" >/dev/null 2>&1 &
  disown || true
}

stop_bins() {
  local bin
  for bin in "$@"; do
    if running "${bin}"; then
      pkill -x "${bin}" >/dev/null 2>&1 || true
    fi
  done
}

# Automount without a tray icon.
ensure_udiskie() {
  local pid cmd=""
  command -v udiskie >/dev/null 2>&1 || return 0
  if running udiskie; then
    pid="$(pgrep -nx udiskie 2>/dev/null || true)"
    if [[ -n "${pid}" && -r "/proc/${pid}/cmdline" ]]; then
      cmd="$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || true)"
    fi
    if [[ "${cmd}" == *"--tray"* ]]; then
      stop_bins udiskie
    else
      return 0
    fi
  fi
  start_bg udiskie
}

apply_text() {
  mkdir -p "${STATE_DIR}"
  printf 'text\n' >"${STATE_FILE}"
  stop_bins nm-applet blueman-applet
  ensure_udiskie
}

cmd="${1:-apply}"
case "${cmd}" in
  status)
    echo text
    ;;
  apply|text|icons|toggle)
    # Always light tray — no Settings toggle.
    apply_text
    ;;
  *)
    echo "Usage: $0 [apply|text|status]" >&2
    exit 2
    ;;
esac
