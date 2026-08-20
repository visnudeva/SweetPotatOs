#!/usr/bin/env bash
# One-shot keybind tips after Swirl starts (live every boot; installed once).
# Two binds per toast, longer display time so mako stays readable.
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

# 8s visible + short gap so the next tip does not overlap
TIP_MS=8000
TIP_SLEEP=9

tip() {
  local title="$1" body="$2"
  notify-send -t "${TIP_MS}" -a "SweetPotato" -i "help-about" \
    -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
    "${title}" "${body}" 2>/dev/null || true
  sleep "${TIP_SLEEP}"
}

sleep 4

if [[ "${LIVE}" -eq 1 ]]; then
  tip "Live tips (1/6)" "Mod+Space → apps
Mod+Return → terminal"
  tip "Live tips (2/6)" "Mod+n → network manager
Mod+w → web browser"
  tip "Live tips (3/6)" "Mod+f → files
Mod+i → installer"
  tip "Live tips (4/6)" "Mod+c → caffeine
Mod+m → maximize/minimize window"
  tip "Live tips (5/6)" "Mod+l → lock
Mod+Shift+d → displays"
  tip "Live tips (6/6)" "Mod+Shift+w → wallpaper
Mod+o → power off"
else
  tip "Tips (1/5)" "Mod+Space → apps
Mod+Return → terminal"
  tip "Tips (2/5)" "Mod+n → network manager
Mod+w → web browser"
  tip "Tips (3/5)" "Mod+f → files
Mod+m → maximize/minimize window"
  tip "Tips (4/5)" "Mod+l → lock
Mod+c → caffeine"
  tip "Tips (5/5)" "Mod+Shift+d → displays
Mod+Shift+w → wallpaper"
fi

: > "${MARKER}"
