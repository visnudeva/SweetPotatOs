#!/usr/bin/env bash
# Save current output configuration (resolution/position/scale) to output.conf
# so ensure-output.sh can restore it on next Swirl start.
# Run this after using wdisplays to persist the changes.
set -euo pipefail

CONF="${HOME}/.config/swirl/output.conf"
tmp="${CONF}.tmp.$$"

mkdir -p "$(dirname "${CONF}")"

# swaymsg returns output info as JSON; extract name + resolution + position + scale
swaymsg -t get_outputs | \
  python3 -c "
import json, sys
outputs = json.load(sys.stdin)
lines = []
for o in outputs:
    if not o.get('active'):
        continue
    name = o['name']
    mode = o.get('current_mode') or {}
    w, h = mode.get('width', 0), mode.get('height', 0)
    rect = o.get('rect') or {}
    x, y = rect.get('x', 0), rect.get('y', 0)
    scale = o.get('scale', 1.0)
    if w and h:
        lines.append(f'output {name} resolution {w}x{h} position {x},{y} scale {scale}')
print('\n'.join(lines))
" > "${tmp}"

mv -f "${tmp}" "${CONF}"
echo "Output config saved to ${CONF}"
cat "${CONF}"
