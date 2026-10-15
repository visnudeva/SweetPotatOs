#!/bin/bash
# One confirmation bar at a time. A second Mod+Escape, Mod+O, or exit
# shortcut does nothing until this one is answered or dismissed.
# Colors follow the active theme. The warning type's yellow is the fallback.
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
  --border-bottom-size 1 \
  --button-gap 12 \
  "$@"
