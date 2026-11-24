#!/usr/bin/env bash
# Once per login, open SweetPotatOs Settings (unless turned off there).
# Toggle: Settings → Desktop → Open Settings at login
# (same file as before: ~/.config/sweetpotatos/login-tip — "off" disables).
set -euo pipefail

TIP_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/login-tip"
if [[ -f "${TIP_FILE}" ]] && [[ "$(tr -d '[:space:]' < "${TIP_FILE}")" == off ]]; then
  exit 0
fi

MARKER="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-tips-shown"
[[ -f "${MARKER}" ]] && exit 0

# Mark first so a slow Settings start cannot double-open on reload.
: > "${MARKER}"

sleep 3

# Already open (user beat us to Mod+,).
if command -v swaymsg >/dev/null 2>&1; then
  if swaymsg -t get_tree 2>/dev/null | grep -Fq '"app_id": "sweetpotato-settings"'; then
    exit 0
  fi
fi

SETTINGS="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/scripts/settings.py"
if [[ ! -f "${SETTINGS}" ]]; then
  SETTINGS=/usr/share/sweetpotato/config/swirl/scripts/settings.py
fi
if [[ ! -f "${SETTINGS}" ]]; then
  exit 0
fi

# Prefer the wrapper when present (sets PATH / display bits).
if command -v sweetpotatos-settings >/dev/null 2>&1; then
  sweetpotatos-settings >/dev/null 2>&1 &
else
  python3 "${SETTINGS}" >/dev/null 2>&1 &
fi
disown || true
