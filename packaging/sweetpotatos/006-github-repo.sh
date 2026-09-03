#!/usr/bin/bash
# Overlay pacman repo moved from SourceForge Files to a GitHub Release.
set -euo pipefail

GH_SERVER='Server = https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo'

fix_file() {
  local f=$1
  [[ -f "${f}" ]] || return 0
  if grep -qE 'downloads\.sourceforge\.net/project/sweetpotatos/repo|sourceforge\.net/.*/sweetpotatos/repo' "${f}"; then
    echo "[migration 006] Pointing ${f} at GitHub overlay release"
    sed -i \
      -e 's|^Server = https://downloads\.sourceforge\.net/project/sweetpotatos/repo/.*|'"${GH_SERVER}"'|' \
      -e 's|^Server = https://sourceforge\.net/.*/sweetpotatos/repo/.*|'"${GH_SERVER}"'|' \
      "${f}"
  fi
}

fix_file /etc/pacman.d/sweetpotatos.conf
fix_file /usr/share/sweetpotatos/pacman/sweetpotatos.conf
