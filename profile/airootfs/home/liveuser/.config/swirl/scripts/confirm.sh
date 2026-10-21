#!/bin/bash
# One confirmation / power-menu bar at a time. A second Mod+Escape
# or exit shortcut does nothing until this one is answered or dismissed.
# Escape or a click outside the bar dismisses it (no X button).
# Colors follow the active theme. With frames on, the bar floats like swirlbar.
lock="${XDG_RUNTIME_DIR:-/tmp}/sweetpotatos-confirm.lock"
ACTIVE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/active.sh"
if [[ -f "${ACTIVE}" ]]; then
  # shellcheck disable=SC1090
  source "${ACTIVE}"
fi
: "${SPO_SURFACE:=1d1f21}"
: "${SPO_TEXT:=f5e6e8}"
: "${SPO_ACCENT:=a73b50}"
: "${SPO_ON_ACCENT:=ffffff}"

panel_args=()
RADIUS=8
FRAME="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/frame"
if [[ -f "${FRAME}" && "$(<"${FRAME}")" == "off" ]]; then
  RADIUS=0
fi
if (( RADIUS > 0 )); then
  gap=8
  if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    bar_json="$(swaymsg -t get_bar_config potato 2>/dev/null || true)"
    if [[ -n "${bar_json}" ]]; then
      g="$(jq -r '.gaps.top // 0' <<<"${bar_json}" 2>/dev/null || echo 0)"
      if [[ "${g}" =~ ^[1-9][0-9]*$ ]]; then
        gap="${g}"
      fi
    fi
  fi
  panel_args=(--panel-radius "${RADIUS}" --panel-margin "${gap}" --panel-border 2)
fi

exec flock -n "$lock" swaynag \
  --font "pango:Noto Sans 10" \
  --background "${SPO_SURFACE}" \
  --text "${SPO_TEXT}" \
  --border "${SPO_ACCENT}" \
  --border-bottom "${SPO_ACCENT}" \
  --button-background "${SPO_ACCENT}" \
  --button-text "${SPO_ON_ACCENT}" \
  --details-background "${SPO_SURFACE}" \
  --message-padding 4 \
  --button-padding 2 \
  --button-border-size 1 \
  --border-bottom-size 2 \
  --button-gap 12 \
  "${panel_args[@]}" \
  "$@"
