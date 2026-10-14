#!/usr/bin/env bash
# Keybind reminder pointing at the Mod+? cheatsheet (once per session).
# Turn it off from the cheatsheet: focus that page and press x.
set -euo pipefail

TIP_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/login-tip"
if [[ -f "${TIP_FILE}" ]] && [[ "$(tr -d '[:space:]' < "${TIP_FILE}")" == off ]]; then
  exit 0
fi

MARKER="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-tips-shown"
[[ -f "${MARKER}" ]] && exit 0

sleep 4
notify-send -t 12000 -a "SweetPotato" -i "help-about" \
  -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
  "Keybind reminder" "Mod+? — keybinds and project links. Mod is Super." \
  2>/dev/null || true

: > "${MARKER}"
