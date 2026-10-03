#!/usr/bin/env bash
# Escape closes an open menu, then a window.
# The compositor owns this key, so wmenu never receives it and would
# keep the keyboard. App launcher, Wi-Fi, and the wallpaper picker all
# run wmenu. With no menu, close the focused window.
if pgrep -x wmenu >/dev/null 2>&1; then
  pkill -x wmenu || true
  exit 0
fi
exec swaymsg kill
