#!/usr/bin/env bash
# Start / restart the Wi‑Fi tray SNI (networkmanager-dmenu on click).
# Used with exec_always so Mod+Shift+c / swaybar rebuild brings the icon back.
set -euo pipefail
SCRIPT="${HOME}/.config/swirl/scripts/network-applet.py"
pkill -f "${HOME}/.config/swirl/scripts/network-applet.py" 2>/dev/null || true
# Brief settle so the previous bus name is released.
sleep 0.2
exec python3 "${SCRIPT}"
