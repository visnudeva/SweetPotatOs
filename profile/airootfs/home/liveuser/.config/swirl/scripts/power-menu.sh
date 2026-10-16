#!/bin/bash
# Full power menu (lock / sleep / logout / reboot / power off) via swirlnag.
# Icons are Nerd Font glyphs; Escape or a click outside the bar dismisses.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ico() {
  printf '<span font="Symbols Nerd Font Mono 12">&#x%X;</span>' "$1"
}

LOCK_CMD="${LOCK_CMD:-swaylock -f -C ${HOME}/.config/swaylock/config}"

# Button order is right-to-left in swirlnag, so power off is added first.
exec "${ROOT}/confirm.sh" -t warning -m 'Power menu' \
  -Z "$(ico 0xF011)" "${ROOT}/poweroff.sh" \
  -Z "$(ico 0xF021)" "${ROOT}/poweroff.sh reboot" \
  -Z "$(ico 0xF08B)" "swaymsg exit" \
  -Z "$(ico 0xF186)" "${ROOT}/suspend.sh" \
  -Z "$(ico 0xF023)" "${LOCK_CMD}"
