#!/bin/bash
# One confirmation bar at a time. A second Mod+Escape, Mod+O, or exit
# shortcut does nothing until this one is answered or dismissed.
lock="${XDG_RUNTIME_DIR:-/tmp}/sweetpotatos-confirm.lock"
exec flock -n "$lock" swaynag "$@"
