#!/usr/bin/env bash
# One-shot keybind tips after Swirl starts (live every boot; installed once).
# Short sequential toasts so mako stays readable.
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

tip() {
  local title="$1" body="$2"
  notify-send -t 5000 -a "SweetPotato" -i "help-about" \
    -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
    "${title}" "${body}" 2>/dev/null || true
  sleep 5
}

sleep 4

if [[ "${LIVE}" -eq 1 ]]; then
  tip "Live tips (1/3)" "Mod+Space → apps
Mod+Return → terminal
Mod+n → Wi‑Fi"
  tip "Live tips (2/3)" "Mod+w → browser
Mod+f → files
Mod+i → installer"
  tip "Live tips (3/3)" "Mod+c → caffeine
Mod+m → expand window
Mod+l → lock"
else
  tip "Tips (1/2)" "Mod+Space → apps
Mod+Return → terminal
Mod+n → Wi‑Fi"
  tip "Tips (2/2)" "Mod+w browser · Mod+f files
Mod+m expand · Mod+l lock
Mod+c caffeine"
fi

: > "${MARKER}"
