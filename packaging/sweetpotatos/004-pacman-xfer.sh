#!/usr/bin/bash
# SourceForge repo URLs redirect (302); pacman needs curl -L via XferCommand.
set -euo pipefail

conf=/etc/pacman.conf
[[ -f "${conf}" ]] || exit 0

if grep -qE '^XferCommand = /usr/bin/curl .*\ -L ' "${conf}"; then
  exit 0
fi

echo "[migration 004] Enabling curl -L XferCommand in ${conf} for SourceForge redirects"

if grep -q '^#XferCommand = /usr/bin/curl -L ' "${conf}"; then
  sed -i 's|^#XferCommand = /usr/bin/curl -L |XferCommand = /usr/bin/curl -L |' "${conf}"
elif grep -q '^#XferCommand = /usr/bin/curl ' "${conf}"; then
  sed -i 's|^#XferCommand = /usr/bin/curl |XferCommand = /usr/bin/curl -L |' "${conf}"
elif ! grep -q '^XferCommand = ' "${conf}"; then
  sed -i '/^\[options\]/a XferCommand = /usr/bin/curl -L -C - -f -o %o %u' "${conf}"
fi
