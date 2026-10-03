#!/usr/bin/env bash
# SweetPotato wallpaper selector — pick an image, set it on all outputs, persist.
set -euo pipefail

WALLPAPER_CONF="${HOME}/.config/swirl/wallpaper.conf"
DIRS=(
  "${HOME}/.local/share/backgrounds"
  "${HOME}/Pictures/Wallpapers"
  "${HOME}/Pictures"
  /usr/share/backgrounds
)

# Colors come from the active theme. Sweet potato is the fallback.
ACTIVE="${HOME}/.config/sweetpotatos/active.sh"
if [[ -f "${ACTIVE}" ]]; then
  # shellcheck disable=SC1090
  source "${ACTIVE}"
fi
: "${SPO_SURFACE:=1d1f21}"
: "${SPO_TEXT:=f5e6e8}"
: "${SPO_ACCENT:=a73b50}"
: "${SPO_ON_ACCENT:=ffffff}"
: "${SPO_HIGHLIGHT:=f79b29}"
: "${SPO_ON_HIGHLIGHT:=1d1f21}"
DMENU=(
  wmenu -i -f "Noto Sans 11" -p wallpaper
  -N "${SPO_SURFACE}ff" -n "${SPO_TEXT}ff"
  -M "${SPO_ACCENT}ff" -m "${SPO_ON_ACCENT}ff"
  -S "${SPO_HIGHLIGHT}ff" -s "${SPO_ON_HIGHLIGHT}ff"
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
  notify-send -t 3000 -a "Wallpaper" -i "sweetpotatos" \
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
tmp="${WALLPAPER_CONF}.tmp.$$"
printf 'output * bg "%s" fill\n' "${conf_img}" > "${tmp}"
mv -f "${tmp}" "${WALLPAPER_CONF}"

notify-send -t 2000 -a "Wallpaper" -i "sweetpotatos" \
  "Wallpaper" "$(basename "${img}")" 2>/dev/null || true
