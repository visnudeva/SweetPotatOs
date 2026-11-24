#!/usr/bin/env bash
# Keybinds panel (Mod+?). GTK UI matching Settings; SPO_RENDER_ONLY keeps a
# plain-text render path for tests.
set -euo pipefail

SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${SCRIPT_DIR}/cheatsheet.py"

ACTIVE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/active.sh"
if [[ -f "${ACTIVE}" ]]; then
  # shellcheck disable=SC1090
  source "${ACTIVE}"
fi
: "${SPO_ACCENT_RGB:=167;59;80}"
: "${SPO_HIGHLIGHT_RGB:=247;155;41}"
: "${SPO_TEXT_RGB:=245;230;232}"
: "${SPO_MUTED_RGB:=170;170;170}"
PINK=$'\033[1;38;2;'"${SPO_ACCENT_RGB}"'m'
ORANGE=$'\033[1;38;2;'"${SPO_HIGHLIGHT_RGB}"'m'
CREAM=$'\033[38;2;'"${SPO_TEXT_RGB}"'m'
MUTED=$'\033[38;2;'"${SPO_MUTED_RGB}"'m'
RESET=$'\033[0m'

render_only() {
  local line
  if [[ ! -f "${SHEET}" ]]; then
    echo "Missing ${SHEET}" >&2
    exit 1
  fi
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${line}" in
      "  SweetPotato"*|"  SweetPotatOs"*)
        printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
      "  Mod = "*)
        printf "%s%s%s\n" "${MUTED}" "${line}" "${RESET}" ;;
      "  Apps"|"  Window / layout"|"  Workspaces / overview"|"  Displays / look"|\
      "  System"|"  Screenshots / media keys"|"  Gestures"|"  Resize mode"*|\
      "  Customize"|"  Desktop / package updates"|"  This page"|"  Settings")
        printf "%s%s%s\n" "${ORANGE}" "${line}" "${RESET}" ;;
      "  sudo sweetpotatos-update"*|"  sweetpotatos-pruning"*)
        printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
      "")
        printf "\n" ;;
      *)
        printf "%s%s%s\n" "${CREAM}" "${line}" "${RESET}" ;;
    esac
  done < "${SHEET}"
}

if [[ "${SPO_RENDER_ONLY:-}" == 1 ]]; then
  render_only
  exit 0
fi

if [[ ! -f "${SHEET}" ]]; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "Missing ${SHEET}" 2>/dev/null || true
  exit 1
fi

if [[ ! -f "${PY}" ]]; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "Missing ${PY}" 2>/dev/null || true
  exit 1
fi

exec python3 "${PY}"
