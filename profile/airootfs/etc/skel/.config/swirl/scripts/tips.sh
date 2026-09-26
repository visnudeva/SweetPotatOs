#!/usr/bin/env bash
# Login tip pointing at the Mod+? cheatsheet (every session).
set -euo pipefail

MARKER="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-tips-shown"
[[ -f "${MARKER}" ]] && exit 0

sleep 4
notify-send -t 12000 -a "SweetPotato" -i "help-about" \
  -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
  "Keybinds" "Mod+? — keybinds & project links. Mod is Super." \
  2>/dev/null || true

: > "${MARKER}"
