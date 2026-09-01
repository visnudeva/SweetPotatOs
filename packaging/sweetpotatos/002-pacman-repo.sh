#!/usr/bin/bash
# Ensure installed systems use the remote [sweetpotatos] repo, not ISO file:// paths.
set -euo pipefail

conf=/etc/pacman.conf
repo_conf=/etc/pacman.d/sweetpotatos.conf

if [[ ! -f "${repo_conf}" && -f /usr/share/sweetpotatos/pacman/sweetpotatos.conf ]]; then
  install -Dm644 /usr/share/sweetpotatos/pacman/sweetpotatos.conf "${repo_conf}"
fi

if [[ -f "${conf}" ]] && grep -q '^\[sweetpotatos\]' "${conf}"; then
  echo "[migration 002] Removing inline [sweetpotatos] from ${conf}"
  awk '
    /^\[sweetpotatos\]/ { skip=1; next }
    /^\[/ && skip { skip=0 }
    !skip { print }
  ' "${conf}" > "${conf}.migration.tmp"
  mv "${conf}.migration.tmp" "${conf}"
fi

if [[ -f "${conf}" ]] && ! grep -qF 'Include = /etc/pacman.d/sweetpotatos.conf' "${conf}"; then
  echo "[migration 002] Adding Include for ${repo_conf}"
  printf '\nInclude = /etc/pacman.d/sweetpotatos.conf\n' >> "${conf}"
fi
