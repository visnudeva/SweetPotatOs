# SweetPotatOs live session — start Sway on tty1 when not already in Wayland
if [[ -z "${WAYLAND_DISPLAY:-}" ]] && [[ "$(tty)" == /dev/tty1 ]]; then
  exec sweetpotatoos-session
fi
