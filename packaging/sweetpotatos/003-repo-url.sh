#!/usr/bin/bash
# Early Second Harvest pointed at repo/$arch/ but packages live in repo/ (flat).
set -euo pipefail

fix_file() {
  local f=$1
  [[ -f "${f}" ]] || return 0
  if grep -q '/repo/\$arch' "${f}"; then
    echo "[migration 003] Fixing repo URL in ${f}"
    sed -i 's|/repo/\$arch|/repo|g' "${f}"
  fi
}

fix_file /etc/pacman.d/sweetpotatos.conf
fix_file /usr/share/sweetpotatos/pacman/sweetpotatos.conf
