#!/usr/bin/env bash
# One-shot keybind tips after Swirl starts (live every boot; installed once).
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

sleep 5

if [[ "${LIVE}" -eq 1 ]]; then
  BODY="Mod+Space launcher · Mod+Return terminal · Mod+n Wi‑Fi · Mod+w browser · Mod+f files · Mod+i installer · Mod+c caffeine"
  TITLE="SweetPotatOs live tips"
else
  BODY="Mod+Space launcher · Mod+Return terminal · Mod+n Wi‑Fi · Mod+w browser · Mod+f files · Mod+l lock · Mod+c caffeine"
  TITLE="SweetPotato tips"
fi

notify-send -t 12000 -a "SweetPotato" -i "help-about" "${TITLE}" "${BODY}" 2>/dev/null || true
: > "${MARKER}"
