#!/usr/bin/env bash
# Apply wallpaper from wallpaper.conf, or a SweetPotato default if missing/broken.
# Never overwrite a saved preference with the fallback — that caused the chosen
# wallpaper to reset to UsefulBinds after a reboot when resolve briefly failed.
set -euo pipefail

CONF="${HOME}/.config/sway/wallpaper.conf"
DIR="${HOME}/.local/share/backgrounds"
FALLBACKS=(
  "${DIR}/UsefulBinds.png"
  "${DIR}/SweetPotato.png"
  "${DIR}/SweetPOTATo.png"
)

expand_path() {
  local p="$1"
  if [[ "${p}" == "~/"* ]]; then
    p="${HOME}/${p#~/}"
  elif [[ "${p}" == "~" ]]; then
    p="${HOME}"
  fi
  printf '%s' "${p}"
}

persist_path() {
  local img="$1"
  if [[ "${img}" == "${HOME}/"* ]]; then
    printf '~%s' "${img#"${HOME}"}"
  else
    printf '%s' "${img}"
  fi
}

read_conf_path() {
  local current=""
  [[ -f "${CONF}" ]] || return 1
  current="$(sed -n 's/^output \* bg "\([^"]*\)" fill.*/\1/p; t; s/^output \* bg \(.*\) fill.*/\1/p' "${CONF}" | head -1)"
  [[ -n "${current}" ]] || return 1
  printf '%s' "${current}"
}

apply_bg() {
  swaymsg output '*' bg "$1" fill >/dev/null 2>&1 || true
}

write_conf() {
  mkdir -p "$(dirname "${CONF}")"
  printf 'output * bg "%s" fill\n' "$(persist_path "$1")" > "${CONF}"
}

mkdir -p "${DIR}"

saved_raw=""
if saved_raw="$(read_conf_path)"; then
  saved="$(expand_path "${saved_raw}")"
  if [[ -f "${saved}" ]]; then
    write_conf "${saved}"
    apply_bg "${saved}"
    exit 0
  fi
  # Saved path is broken/missing: show a fallback for this session only.
  # Keep wallpaper.conf untouched so the preference is not lost.
  for f in "${FALLBACKS[@]}"; do
    if [[ -f "${f}" ]]; then
      apply_bg "${f}"
      exit 0
    fi
  done
  exit 0
fi

# No preference yet — persist and apply a default.
for f in "${FALLBACKS[@]}"; do
  if [[ -f "${f}" ]]; then
    write_conf "${f}"
    apply_bg "${f}"
    exit 0
  fi
done
