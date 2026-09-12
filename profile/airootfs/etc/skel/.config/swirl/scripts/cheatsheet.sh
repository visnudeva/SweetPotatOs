#!/usr/bin/env bash
# Floating terminal cheatsheet (toggle with Mod+?).
set -euo pipefail

APP_ID="sweetpotato-cheatsheet"
SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
TERM_BIN="${TERM_BIN:-foot}"

if ! command -v "${TERM_BIN}" >/dev/null 2>&1; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "foot not found" 2>/dev/null || true
  exit 1
fi

if [[ ! -f "${SHEET}" ]]; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "Missing ${SHEET}" 2>/dev/null || true
  exit 1
fi

# Toggle: second press closes an open sheet.
if swaymsg -t get_tree 2>/dev/null | grep -Fq "\"app_id\": \"${APP_ID}\""; then
  swaymsg "[app_id=\"${APP_ID}\"] kill" >/dev/null 2>&1 || true
  exit 0
fi

exec "${TERM_BIN}" -a "${APP_ID}" -T "SweetPotato keybinds" \
  sh -c 'cat "$1"; printf "\n  Press q to close (or Mod+? again).\n"; while IFS= read -rsn1 k; do
    case "$k" in q|Q) exit 0 ;; esac
  done' sh "${SHEET}"
