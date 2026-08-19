#!/usr/bin/env bash
# Restore saved output configuration (resolution/position/scale) on Swirl start.
# Changes made with wdisplays are saved by save-output.sh; this script re-applies them.
set -euo pipefail

CONF="${HOME}/.config/swirl/output.conf"

[[ -f "${CONF}" ]] || exit 0

# Feed each saved output line to swaymsg
while IFS= read -r line; do
  [[ -z "${line}" || "${line}" == \#* ]] && continue
  swaymsg "${line}" >/dev/null 2>&1 || true
done < "${CONF}"
