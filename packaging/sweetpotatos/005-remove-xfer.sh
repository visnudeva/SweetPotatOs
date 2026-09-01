#!/usr/bin/bash
# Global XferCommand breaks official repo GPG checks (gpgme: No data).
set -euo pipefail

conf=/etc/pacman.conf
[[ -f "${conf}" ]] || exit 0

if grep -q '^XferCommand = ' "${conf}"; then
  echo "[migration 005] Removing XferCommand from ${conf}"
  sed -i '/^XferCommand = /d' "${conf}"
fi
