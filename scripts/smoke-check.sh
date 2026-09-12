#!/usr/bin/env bash
# Smoke-check SweetPotatOs profile consistency (no root required).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${ROOT}/profile/airootfs"
FAIL=0

ok() { echo "[OK] $*"; }
bad() { echo "[FAIL] $*"; FAIL=1; }

check_file() {
  local f="$1"
  # Accept dangling enable-symlinks (unit path exists after pacstrap).
  if [[ -L "${f}" || -e "${f}" ]]; then
    ok "exists ${f#${ROOT}/}"
  else
    bad "missing ${f#${ROOT}/}"
  fi
}

check_grep() {
  local pat="$1" f="$2" label="$3"
  if [[ -f "${f}" ]] && grep -qE "${pat}" "${f}"; then
    ok "${label}"
  else
    bad "${label} (${f#${ROOT}/})"
  fi
}

check_nogrep() {
  local pat="$1" f="$2" label="$3"
  if [[ -f "${f}" ]] && grep -qE "${pat}" "${f}"; then
    bad "${label} (${f#${ROOT}/})"
  else
    ok "${label}"
  fi
}

echo "== SweetPotatOs smoke check =="

check_file "${ISO}/usr/local/bin/swirl"
check_file "${ISO}/etc/skel/.local/bin/swirl"
check_file "${ISO}/etc/skel/.config/foot/foot.ini"
check_file "${ISO}/etc/skel/.config/swirl/scripts/tips.sh"
check_file "${ISO}/etc/skel/.config/swirl/scripts/cheatsheet.sh"
check_file "${ISO}/etc/skel/.config/swirl/cheatsheet.txt"
check_file "${ISO}/etc/systemd/system/multi-user.target.wants/bluetooth.service"
check_file "${ISO}/etc/systemd/system/multi-user.target.wants/power-profiles-daemon.service"

check_grep '\[colors-dark\]' "${ISO}/etc/skel/.config/foot/foot.ini" "foot uses [colors-dark]"
check_grep 'alpha=1\.0' "${ISO}/etc/skel/.config/foot/foot.ini" "foot opaque alpha=1.0"
check_grep 'set \$term foot' "${ISO}/etc/skel/.config/swirl/config" "skel Mod+Return → foot"
check_grep 'set \$term foot' "${ISO}/home/liveuser/.config/swirl/config" "liveuser Mod+Return → foot"
check_grep 'sleep 3' "${ISO}/etc/skel/.config/swirl/scripts/status.sh" "status bar every 3s"
check_grep 'default_input = password' "${ISO}/etc/ly/config.ini" "Ly focuses password"
check_grep 'rfkill unblock bluetooth' "${ISO}/etc/skel/.config/swirl/config" "bluetooth unblock on session start"
check_grep 'tips\.sh' "${ISO}/etc/skel/.config/swirl/config" "first-boot / live tips"
check_grep 'exec_always --no-startup-id /usr/local/bin/sweetpotatos-sway-xkb-watch' \
  "${ISO}/home/liveuser/.config/swirl/config" "liveuser locale1 keyboard watcher"
check_nogrep 'sweetpotatos-sway-xkb-watch' "${ISO}/etc/skel/.config/swirl/config" \
  "skel has no live Calamares xkb watcher"
check_file "${ISO}/usr/local/bin/sweetpotatos-sway-xkb-watch"
check_file "${ISO}/usr/local/bin/sweetpotatos-sway-xkb-sync"
[[ ! -e "${ISO}/usr/local/bin/spo-upgrade" ]] && ok "no spo-upgrade binary" || bad "spo-upgrade still present"
if grep -RIl 'spo-upgrade' "${ISO}" 2>/dev/null | head -n1 | grep -q .; then
  bad "spo-upgrade string still in airootfs"
else
  ok "no spo-upgrade references in airootfs"
fi
check_grep '^spore$' "${ROOT}/profile/packages.x86_64" "spore package listed"
check_grep '^VERSION_ID=' "${ISO}/usr/local/share/sweetpotatos/os-release" "os-release has VERSION_ID"
check_grep 'fingerprint' "${ISO}/usr/local/bin/sweetpotatos-sway-xkb-watch" \
  "xkb watcher polls locale1 via busctl"
check_nogrep '^[[:space:]]*dbus-monitor' "${ISO}/usr/local/bin/sweetpotatos-sway-xkb-watch" \
  "xkb watcher does not invoke dbus-monitor"
check_grep 'name: "bluetooth.service"' \
  "${ROOT}/profile/airootfs/etc/calamares/modules/services-systemd.conf" "Calamares enables bluetooth"
check_grep 'name: "power-profiles-daemon.service"' \
  "${ROOT}/profile/airootfs/etc/calamares/modules/services-systemd.conf" "Calamares enables power-profiles-daemon"

check_nogrep '^kitty$' "${ROOT}/profile/packages.x86_64" "no kitty package"
check_nogrep '^wlsunset$' "${ROOT}/profile/packages.x86_64" "no wlsunset package"
check_nogrep '^gammastep$' "${ROOT}/profile/packages.x86_64" "no gammastep package"
[[ ! -e "${ISO}/etc/skel/.config/kitty" ]] && ok "no skel kitty config" || bad "skel still has kitty config"
[[ ! -e "${ISO}/home/liveuser/.config/kitty" ]] && ok "no liveuser kitty config" || bad "liveuser still has kitty config"
[[ ! -e "${ISO}/etc/skel/.config/sway" ]] && ok "no skel sway config dir" || bad "skel still has sway config dir"

check_grep '^foot$' "${ROOT}/profile/packages.x86_64" "foot package listed"
check_grep '^btop$' "${ROOT}/profile/packages.x86_64" "btop package listed"
check_grep '^power-profiles-daemon$' "${ROOT}/profile/packages.x86_64" "power-profiles-daemon listed"
check_grep 'nwg-displays\.sh' "${ISO}/etc/skel/.config/swirl/config" "skel nwg-displays wrapper keybind"
check_grep 'sweetpotatos-displays' "${ISO}/etc/skel/.local/share/applications/nwg-displays.desktop" "skel Displays Exec uses PATH launcher"
check_grep 'nwg-displays\.sh' "${ISO}/usr/local/bin/sweetpotatos-displays" "system sweetpotatos-displays delegates to swirl wrapper"
check_grep 'GenericName=nwg-displays' "${ISO}/etc/skel/.local/share/applications/nwg-displays.desktop" "skel Displays shows nwg-displays generic name"
check_grep 'SWAYSOCK|I3SOCK' "${ISO}/etc/skel/.config/swirl/scripts/nwg-displays.sh" "nwg-displays wrapper finds IPC socket"
check_grep 'Mod\+\?' "${ISO}/etc/skel/.config/swirl/scripts/tips.sh" "tips mention Mod+? cheatsheet"
check_nogrep 'Live tips' "${ISO}/etc/skel/.config/swirl/scripts/tips.sh" "no multi-tip notification sequence"
check_grep 'cheatsheet\.sh' "${ISO}/etc/skel/.config/swirl/config" "Mod+? cheatsheet bind"
check_grep 'SPixelBG' "${ISO}/etc/skel/.config/waypaper/config.ini" "default wallpaper SPixelBG"
[[ ! -e "${ISO}/etc/skel/Pictures/Wallpapers/UsefulBinds.png" ]] && ok "no UsefulBinds wallpaper" || bad "UsefulBinds still present"
[[ ! -e "${ISO}/etc/skel/Pictures/Wallpapers/BindsBG.png" ]] && ok "no BindsBG wallpaper" || bad "BindsBG still present"
check_grep 'start-kanshi\.sh' "${ISO}/etc/skel/.config/swirl/config" "skel starts kanshi from saved outputs"
check_grep 'save-display-layout\.sh' "${ISO}/etc/skel/.config/swirl/config" "skel save-display-layout keybind"
check_grep 'sway/workspaces' "${ISO}/etc/skel/.config/swirl/config" "skel includes sway workspaces"

if [[ "${FAIL}" -ne 0 ]]; then
  echo "== FAILED =="
  exit 1
fi
echo "== PASSED =="
