#!/usr/bin/env bash
# Tiled terminal cheatsheet (toggle with Mod+?). SPO colors; w → website.
set -euo pipefail

APP_ID="sweetpotato-cheatsheet"
SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
TERM_BIN="${TERM_BIN:-foot}"
SITE_URL="https://sweetpotatos.sourceforge.io/"

PINK=$'\033[1;38;2;167;59;80m'
ORANGE=$'\033[1;38;2;247;155;41m'
CREAM=$'\033[38;2;245;230;232m'
MUTED=$'\033[38;2;170;170;170m'
RESET=$'\033[0m'

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

export SPO_CHEATSHEET="${SHEET}"
export SPO_SITE_URL="${SITE_URL}"
export SPO_PINK="${PINK}" SPO_ORANGE="${ORANGE}" SPO_CREAM="${CREAM}" SPO_MUTED="${MUTED}" SPO_RESET="${RESET}"

# Request a readable column; compositor then tiles it (~half width via for_window).
"${TERM_BIN}" -a "${APP_ID}" -T "SweetPotato help" \
  -W 78x42 \
  -o colors-dark.background=1d1f21 \
  -o colors-dark.foreground=f5e6e8 \
  -o colors-dark.alpha=1.0 \
  bash -c '
set -euo pipefail
PINK="${SPO_PINK}" ORANGE="${SPO_ORANGE}" CREAM="${SPO_CREAM}" MUTED="${SPO_MUTED}" RESET="${SPO_RESET}"
SHEET="${SPO_CHEATSHEET}"
SITE_URL="${SPO_SITE_URL}"

while IFS= read -r line || [[ -n "${line}" ]]; do
  case "${line}" in
    "  SweetPotato"*)
      printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
    "  Mod = "*)
      printf "%s%s%s\n" "${MUTED}" "${line}" "${RESET}" ;;
    "  Apps"|"  Window / layout"|"  Workspaces / overview"|"  Displays / look"|\
    "  System"|"  Screenshots / media keys"|"  Gestures"|"  Resize mode"*|\
    "  Customize"|"  Desktop / package updates"|"  Project")
      printf "%s%s%s\n" "${ORANGE}" "${line}" "${RESET}" ;;
    "  w  "*|"  sudo sweetpotatos-update"*)
      printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
    "")
      printf "\n" ;;
    *)
      printf "%s%s%s\n" "${CREAM}" "${line}" "${RESET}" ;;
  esac
done < "${SHEET}"
printf "\n%s  w  website · q or Mod+?  close%s\n" "${MUTED}" "${RESET}"

open_site() {
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${SITE_URL}" >/dev/null 2>&1 || true
  elif command -v brave-origin >/dev/null 2>&1; then
    brave-origin "${SITE_URL}" >/dev/null 2>&1 || true
  fi
}

while IFS= read -rsn1 k; do
  case "${k}" in
    q|Q) exit 0 ;;
    w|W) open_site ;;
  esac
done
' &
foot_pid=$!

# Prefer a ~half-strip width so the bind list is not crammed into a thin column.
for _ in 1 2 3 4 5 6 7 8; do
  if swaymsg -t get_tree 2>/dev/null | grep -Fq "\"app_id\": \"${APP_ID}\""; then
    swaymsg "[app_id=\"${APP_ID}\"] resize set width 50 ppt" >/dev/null 2>&1 || true
    break
  fi
  sleep 0.05
done

wait "${foot_pid}"
