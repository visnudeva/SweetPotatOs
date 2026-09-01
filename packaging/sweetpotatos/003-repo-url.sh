#!/usr/bin/bash
# Early Second Harvest pointed at repo/$arch/ but packages live in repo/x86_64/.
set -euo pipefail

fix_file() {
  local f=$1
  [[ -f "${f}" ]] || return 0
  if grep -q 'sf-mirror.net' "${f}"; then
    echo "[migration 003] Removing dead sf-mirror.net from ${f}"
    sed -i '/sf-mirror.net/d' "${f}"
  fi
  if grep -q '/repo/\$arch' "${f}"; then
    echo "[migration 003] Fixing repo URL in ${f}"
    sed -i 's|/repo/\$arch|/repo/x86_64|g' "${f}"
  elif grep -qE 'project/sweetpotatos/repo[[:space:]]*$' "${f}"; then
    echo "[migration 003] Fixing flat repo URL in ${f}"
    sed -i 's|project/sweetpotatos/repo$|project/sweetpotatos/repo/x86_64|g' "${f}"
  fi
}

fix_file /etc/pacman.d/sweetpotatos.conf
fix_file /usr/share/sweetpotatos/pacman/sweetpotatos.conf
