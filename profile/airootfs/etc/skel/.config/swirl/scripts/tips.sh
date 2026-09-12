#!/usr/bin/env bash
# One-shot tip pointing at the Mod+? cheatsheet (live every boot; installed once).
set -euo pipefail

CONF="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl"
LIVE=0
if [[ "$(id -un 2>/dev/null || true)" == "liveuser" ]] || [[ -d /run/archiso ]]; then
  LIVE=1
fi

if [[ "${LIVE}" -eq 1 ]]; then
  MARKER="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-tips-shown"
else
  MARKER="${CONF}/.tips-shown"
  mkdir -p "${CONF}"
fi

[[ -f "${MARKER}" ]] && exit 0

sleep 4
notify-send -t 12000 -a "SweetPotato" -i "help-about" \
  -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
  "Keybinds" "Press Mod+? for the cheatsheet (toggle). Mod is Super." \
  2>/dev/null || true

: > "${MARKER}"
