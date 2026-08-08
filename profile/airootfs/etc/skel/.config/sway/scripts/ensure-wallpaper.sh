#!/usr/bin/env bash
# Apply wallpaper from wallpaper.conf, or a SweetPotato default if missing/broken.
set -euo pipefail

CONF="${HOME}/.config/sway/wallpaper.conf"
DIR="${HOME}/.local/share/backgrounds"
FALLBACKS=(
  "${DIR}/UsefulBinds.png"
  "${DIR}/SweetPotato.png"
  "${DIR}/SweetPOTATo.png"
)

resolve() {
  local current="" f
  if [[ -f "${CONF}" ]]; then
    current="$(sed -n 's/^output \* bg "\([^"]*\)" fill.*/\1/p; t; s/^output \* bg \(.*\) fill.*/\1/p' "${CONF}" | head -1)"
    current="${current/#\~/${HOME}}"
  fi
  if [[ -n "${current}" && -f "${current}" ]]; then
    echo "${current}"
    return 0
  fi
  for f in "${FALLBACKS[@]}"; do
    if [[ -f "${f}" ]]; then
      echo "${f}"
      return 0
    fi
  done
  return 1
}

chosen="$(resolve)" || exit 0
mkdir -p "$(dirname "${CONF}")" "${DIR}"
printf 'output * bg "%s" fill\n' "${chosen}" > "${CONF}"
swaymsg output '*' bg "${chosen}" fill >/dev/null 2>&1 || true
