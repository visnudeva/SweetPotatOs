#!/usr/bin/env bash
# Detailed status was removed — the bar stays thin (volume/battery/wifi/BT/clock).
# Kept as a no-op so old keybinds / Settings callers exit cleanly.
# Usage: status-detail.sh [on|off|toggle|status]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_FILE="${ROOT}/sweetpotatos/status-detail"

# Drop any leftover toggle state from older builds.
rm -f "${STATE_FILE}"

case "${1:-status}" in
  status) echo off ;;
  on|off|enable|disable|toggle) ;;
  *)
    echo "Usage: $0 [on|off|toggle|status]" >&2
    exit 2
    ;;
esac
