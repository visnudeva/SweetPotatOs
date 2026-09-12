#!/usr/bin/bash
# Default browser is Brave Origin (Mod+w). Install it if missing; keep Firefox
# if already present — only retarget the Swirl $web keybind.
set -euo pipefail

echo "[migration 007] Ensuring Brave Origin is the Mod+w browser"

# Overlay install via spo-upgrade usually already placed brave-origin-bin.
# Fall back to pacman if the package landed in the local/remote repo.
if ! command -v brave-origin >/dev/null 2>&1; then
  if pacman -Si brave-origin-bin &>/dev/null; then
    pacman -S --needed --noconfirm brave-origin-bin || true
  else
    echo "[migration 007] WARNING: brave-origin-bin not found; install via spo-upgrade overlay or: yay -S brave-origin-bin"
  fi
fi

patch_web_bind() {
  local f=$1
  [[ -f "${f}" ]] || return 0
  if grep -qE '^[[:space:]]*set \$web[[:space:]]+firefox([[:space:]]|$)' "${f}"; then
    echo "[migration 007] Retargeting Mod+w in ${f}"
    sed -i -E 's|^([[:space:]]*set \$web[[:space:]]+)firefox([[:space:]]*)$|\1brave-origin\2|' "${f}"
  fi
}

# Skel for future users
patch_web_bind /etc/skel/.config/swirl/config
patch_web_bind /etc/skel/.config/swirl/config-us
patch_web_bind /etc/skel/.config/swirl/config-fr

# Existing home directories (do not remove Firefox)
shopt -s nullglob
for home in /home/*; do
  [[ -d "${home}" ]] || continue
  patch_web_bind "${home}/.config/swirl/config"
  patch_web_bind "${home}/.config/swirl/config-us"
  patch_web_bind "${home}/.config/swirl/config-fr"
done
shopt -u nullglob

# Do not uninstall firefox — users who want it can keep launching it from the app menu.
if pacman -Q firefox &>/dev/null; then
  echo "[migration 007] Firefox remains installed (no longer Mod+w); remove with: sudo pacman -Rns firefox"
fi
