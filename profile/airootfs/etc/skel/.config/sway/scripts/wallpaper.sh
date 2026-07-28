#!/usr/bin/env bash
# SweetPotato wallpaper selector — pick an image, set it on all outputs, persist.
set -euo pipefail

WALLPAPER_CONF="${HOME}/.config/sway/wallpaper.conf"
DIRS=(
  "${HOME}/.local/share/backgrounds"
  "${HOME}/Pictures/Wallpapers"
  "${HOME}/Pictures"
  /usr/share/backgrounds
)

# Colors: charcoal / potato orange selection / soft fg (matches app launcher)
DMENU=(
  wmenu -i -f "Noto Sans 11" -p wallpaper
  -N 1d1f21ff -n f5e6e8ff
  -M a73b50ff -m ffffffff
  -S f79b29ff -s 1d1f21ff
)

is_image() {
  case "${1,,}" in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp|*.tif|*.tiff) return 0 ;;
    *) return 1 ;;
  esac
}

declare -a display_list=()
declare -A path_of=()

for dir in "${DIRS[@]}"; do
  [[ -d "${dir}" ]] || continue
  while IFS= read -r file; do
    [[ -n "${file}" ]] || continue
    is_image "${file}" || continue
    if [[ "${file}" == "${HOME}/"* ]]; then
      label="~${file#"${HOME}"}"
    else
      label="${file}"
    fi
    if [[ -z "${path_of[${label}]+x}" ]]; then
      path_of["${label}"]="${file}"
      display_list+=("${label}")
    fi
  done < <(find "${dir}" -type f 2>/dev/null | sort)
done

if ((${#display_list[@]} == 0)); then
  notify-send -t 3000 -a "Wallpaper" -i "sweetpotatoos" \
    "Wallpaper" "No images found. Drop files in ~/.local/share/backgrounds" 2>/dev/null || true
  exit 1
fi

choice="$(printf '%s\n' "${display_list[@]}" | "${DMENU[@]}")" || exit 0
[[ -n "${choice}" ]] || exit 0

img="${path_of[${choice}]:-}"
[[ -n "${img}" && -f "${img}" ]] || exit 1

swaymsg output '*' bg "${img}" fill >/dev/null

mkdir -p "$(dirname "${WALLPAPER_CONF}")"
# Persist with ~ when under $HOME so configs stay portable across users/ISOs
if [[ "${img}" == "${HOME}/"* ]]; then
  conf_img="~${img#"${HOME}"}"
else
  conf_img="${img}"
fi
printf 'output * bg "%s" fill\n' "${conf_img}" > "${WALLPAPER_CONF}"

notify-send -t 2000 -a "Wallpaper" -i "sweetpotatoos" \
  "Wallpaper" "$(basename "${img}")" 2>/dev/null || true
