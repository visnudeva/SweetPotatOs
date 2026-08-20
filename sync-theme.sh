#!/usr/bin/env bash
# Sync SweetPotato theme → live home + SweetPotatOs airootfs (skel + liveuser).
# Run from anywhere. Expects SweetPotato as a sibling of SweetPotatOs by default.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SP="${SWEETPOTATO_DIR:-$(cd "${ROOT}/../SweetPotato" 2>/dev/null && pwd || true)}"
ISO="${ROOT}/profile/airootfs"
HOME_DIR="${HOME}"
SYNC_LIVE=1
LIVE_FLAG=""

usage() {
  echo "Usage: $0 [--iso-only|--live]" >&2
  echo "  --iso-only  write airootfs only (default on GNOME/Bluefin hosts)" >&2
  echo "  --live      also copy theme into \$HOME (Swirl/Arch session)" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso-only) SYNC_LIVE=0; LIVE_FLAG=iso; shift ;;
    --live) SYNC_LIVE=1; LIVE_FLAG=live; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

# Papirus + Arch glycin paths in $HOME blank half the GNOME icons on Bluefin.
if [[ "${SYNC_LIVE}" -eq 1 && "${LIVE_FLAG}" != "live" && "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]]; then
  echo "GNOME session detected — skipping live \$HOME (pass --live to force)."
  SYNC_LIVE=0
fi

if [[ -z "${SP}" || ! -d "${SP}/swirl" ]]; then
  echo "SweetPotato repo not found. Set SWEETPOTATO_DIR=/path/to/SweetPotato" >&2
  exit 1
fi

inject_calamares_float() {
  local f="$1"
  if ! grep -q 'io.calamares.calamares' "${f}"; then
    sed -i '/^include \/etc\/sway\/config.d\/\*/i\
# Calamares installer (Wayland app_id)\
for_window [app_id="io.calamares.calamares"] floating enable\
' "${f}"
  fi
}

inject_live_caffeine() {
  local f="$1"
  # Live ISO: start with caffeine on so idle lock/sleep cannot interrupt install
  if grep -q 'caffeine.sh on' "${f}"; then
    return 0
  fi
  if grep -q '^exec swayidle' "${f}"; then
    sed -i '/^exec swayidle -w \\$/,/^[[:space:]]*before-sleep/d' "${f}"
  fi
  sed -i '/^### Idle configuration/a\
#\
# Live ISO: caffeine on by default so install does not sleep/lock\
exec ~/.config/swirl/scripts/caffeine.sh on
' "${f}"
}

inject_live_xkb_watch() {
  local f="$1"
  # Mirror Calamares locale1 keyboard picks into the running Swirl session.
  # exec_always + full path: restart after reload; do not depend on session PATH.
  if grep -q 'sweetpotatos-sway-xkb-watch' "${f}"; then
    sed -i -E 's|^exec(_always)?( --no-startup-id)? (/.*/)?sweetpotatos-sway-xkb-watch$|exec_always --no-startup-id /usr/local/bin/sweetpotatos-sway-xkb-watch|' "${f}"
    return 0
  fi
  sed -i '/^### Input configuration/i\
# Calamares (Wayland) updates systemd-localed; push that into Swirl live\
exec_always --no-startup-id /usr/local/bin/sweetpotatos-sway-xkb-watch
' "${f}"
}

inject_iso_display() {
  local f="$1"
  # ISO: waypaper + persistent display layout (nwg-displays / kanshi / sway includes).
  sed -i 's|exec_always ~/.config/swirl/scripts/ensure-wallpaper.sh|exec_always waypaper --restore|' "${f}"
  if ! grep -q 'start-kanshi.sh' "${f}"; then
    sed -i '/^exec_always waypaper --restore/a\
exec --no-startup-id ~/.config/swirl/scripts/start-kanshi.sh\
exec --no-startup-id sh -c '\''sleep 0.5; [ -s "$HOME/.config/sway/outputs" ] && swaymsg source "$HOME/.config/sway/outputs" 2>/dev/null || true'\''' "${f}"
  fi
  if ! grep -q 'save-display-layout.sh' "${f}"; then
    sed -i '/bindsym \$mod+Shift+d exec ~\/.config\/swirl\/scripts\/nwg-displays.sh/a\
    bindsym $mod+Ctrl+d exec ~/.config/swirl/scripts/save-display-layout.sh' "${f}"
  fi
  if ! grep -q 'sway/workspaces' "${f}"; then
    sed -i '/^include \/etc\/sway\/config.d\/\*/i\
# nwg-displays / save-display-layout persist monitor layout here\
include ~/.config/sway/outputs\
include ~/.config/sway/workspaces\
' "${f}"
  fi
  if ! grep -q 'nwg-displays.sh' "${f}"; then
    sed -i '/bindsym \$mod+Shift+w exec/a\
\
    # Display layout\
    bindsym $mod+Shift+d exec ~/.config/swirl/scripts/nwg-displays.sh\
    bindsym $mod+Ctrl+d exec ~/.config/swirl/scripts/save-display-layout.sh' "${f}"
    sed -i 's|bindsym \$mod+Shift+w exec ~/.config/swirl/scripts/wallpaper.sh|bindsym $mod+Shift+w exec waypaper|' "${f}"
  fi
}

inject_live_calamares() {
  local f="$1"
  if ! grep -q 'bindsym \$mod+i exec sweetpotatos-calamares' "${f}"; then
    sed -i '/bindsym \$mod+n exec networkmanager_dmenu/a\
\
    # Install SweetPotatOs to disk\
    bindsym $mod+i exec sweetpotatos-calamares
' "${f}"
  fi
  inject_live_caffeine "${f}"
  inject_live_xkb_watch "${f}"
  # Autostart installer after the session is up (Archcraft-style sudo -E launcher)
  sed -i '/Autostart installer on the live ISO session/,+1d' "${f}"
  sed -i '/^include \/etc\/sway\/config.d\/\*/i\
# Autostart installer on the live ISO session\
exec sh -c '\''sleep 5; sweetpotatos-calamares'\''\
' "${f}"
  sed -i 's|exec --no-startup-id sh -c.*polkit.*|exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1|' "${f}"
  inject_calamares_float "${f}"
}

sync_common_into() {
  local dest="$1"
  mkdir -p \
    "${dest}/.config/swirl/scripts" \
    "${dest}/.config/kanshi" \
    "${dest}/.local/share/applications" \
    "${dest}/.config/gtk-3.0" "${dest}/.config/gtk-4.0" \
    "${dest}/.config/foot" "${dest}/.config/mako" "${dest}/.config/swaylock" \
    "${dest}/.config/geany/colorschemes" "${dest}/.config/xsettingsd" \
    "${dest}/.config/fastfetch" "${dest}/.config/environment.d" \
    "${dest}/.config/xdg-desktop-portal" "${dest}/.config/networkmanager-dmenu" \
    "${dest}/.config/systemd/user" \
    "${dest}/.themes" "${dest}/.local/share/backgrounds" "${dest}/.local/bin" \
    "${dest}/.local/share/glycin-loaders/2+/conf.d" \
    "${dest}/.config/xfce4/xfconf/xfce-perchannel-xml" \
    "${dest}/Pictures/Screenshots"

  cp -f "${SP}/swirl/config" "${dest}/.config/swirl/config-fr"
  cp -f "${SP}/swirl/config-us" "${dest}/.config/swirl/config-us"
  cp -f "${SP}"/swirl/scripts/*.sh "${dest}/.config/swirl/scripts/"
  cp -f "${SP}/swirl/scripts/autotile.lua" "${dest}/.config/swirl/scripts/autotile.lua"
  chmod 755 "${dest}/.config/swirl/scripts/"*.sh
  if [[ -f "${SP}/kanshi/config" ]]; then
    cp -f "${SP}/kanshi/config" "${dest}/.config/kanshi/config"
  fi
  if [[ -f "${SP}/applications/nwg-displays.desktop" ]]; then
    cp -f "${SP}/applications/nwg-displays.desktop" \
      "${dest}/.local/share/applications/nwg-displays.desktop"
  fi
  cp -f "${SP}/gtk-3.0/"* "${dest}/.config/gtk-3.0/"
  cp -f "${SP}/gtk-4.0/"* "${dest}/.config/gtk-4.0/"
  cp -f "${SP}/foot/foot.ini" "${dest}/.config/foot/"
  cp -f "${SP}/mako/config" "${dest}/.config/mako/"
  cp -f "${SP}/swaylock/config" "${dest}/.config/swaylock/"
  cp -f "${SP}/geany/colorschemes/sweetpotato.conf" "${dest}/.config/geany/colorschemes/"
  cp -f "${SP}/xsettingsd/xsettingsd.conf" "${dest}/.config/xsettingsd/"
  cp -f "${SP}/fastfetch/config.jsonc" "${dest}/.config/fastfetch/"
  cp -f "${SP}/fastfetch/SPLogo.png" "${dest}/.config/fastfetch/"
  cp -f "${SP}/fastfetch/SPLogo.asc" "${dest}/.config/fastfetch/"
  # ISO trees: absolute system path (airootfs ships the logo under /usr/local/share)
  if [[ "${dest}" == "${ISO}"/* ]]; then
    sed -i 's|"source": "~/.config/fastfetch/SPLogo\.png"|"source": "/usr/local/share/sweetpotatos/SPLogo.png"|' \
      "${dest}/.config/fastfetch/config.jsonc"
  fi
  cp -f "${SP}/xdg-desktop-portal/sway-portals.conf" "${dest}/.config/xdg-desktop-portal/sway-portals.conf"
  cp -f "${SP}/xdg-desktop-portal/sway-portals.conf" "${dest}/.config/xdg-desktop-portal/wlroots-portals.conf"
  cp -f "${SP}/xdg-desktop-portal/sway-portals.conf" "${dest}/.config/xdg-desktop-portal/swayfx-portals.conf"
  cp -f "${SP}/xdg-desktop-portal/sway-portals.conf" "${dest}/.config/xdg-desktop-portal/portals.conf"
  cp -f "${SP}/networkmanager-dmenu/config.ini" "${dest}/.config/networkmanager-dmenu/"
  cp -a "${SP}/themes/SweetPotato" "${dest}/.themes/"
  cp -f "${SP}/backgrounds/"*.png "${dest}/.local/share/backgrounds/"
  cp -f "${SP}/backgrounds/"*.png "${dest}/Pictures/Wallpapers/" 2>/dev/null || true
  cp -f "${SP}/bin/swirl" "${dest}/.local/bin/swirl"
  chmod 755 "${dest}/.local/bin/swirl"
  cp -f "${SP}/bin/sweetpotatos-displays" "${dest}/.local/bin/sweetpotatos-displays"
  chmod 755 "${dest}/.local/bin/sweetpotatos-displays"
  rm -f "${dest}/.local/bin/sway"
  cp -f "${SP}/glycin-loaders/glycin-svg.conf" "${dest}/.local/share/glycin-loaders/2+/conf.d/"
  # Wallpaper is managed by waypaper; drop any legacy wallpaper.conf.
  rm -f "${dest}/.config/swirl/wallpaper.conf"
  # Swirl reads ~/.config/sway/config *before* swirl — never leave a leftover sway dir.
  # Default terminal is foot — drop any leftover kitty config.
  rm -rf "${dest}/.config/sway" "${dest}/.config/kitty"
  if [[ -f "${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" ]] \
     && [[ "${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
          != "${dest}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" ]]; then
    cp -f "${HOME_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
      "${dest}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
  fi
  if [[ -d "${SP}/systemd/user/xdg-desktop-portal-gtk.service.d" ]]; then
    mkdir -p "${dest}/.config/systemd/user/xdg-desktop-portal-gtk.service.d"
    cp -f "${SP}/systemd/user/xdg-desktop-portal-gtk.service.d/"* \
      "${dest}/.config/systemd/user/xdg-desktop-portal-gtk.service.d/"
  fi
  if [[ -f "${SP}/systemd/user/polkit-gnome-authentication-agent-1.service" ]]; then
    cp -f "${SP}/systemd/user/polkit-gnome-authentication-agent-1.service" \
      "${dest}/.config/systemd/user/"
  fi
}

echo "Source: ${SP}"
echo "ISO:    ${ISO}"
if [[ "${SYNC_LIVE}" -eq 1 ]]; then
  echo "Live:   ${HOME_DIR}"
else
  echo "Live:   (skipped)"
fi

# Live (Swirl/Arch). Skipped on GNOME so Bluefin ISO builds do not clobber Adwaita.
if [[ "${SYNC_LIVE}" -eq 1 ]]; then
  sync_common_into "${HOME_DIR}"
  if grep -q 'xkb_layout "us"' "${HOME_DIR}/.config/swirl/config" 2>/dev/null; then
    cp -f "${SP}/swirl/config-us" "${HOME_DIR}/.config/swirl/config"
  else
    cp -f "${SP}/swirl/config" "${HOME_DIR}/.config/swirl/config"
  fi
  rm -rf "${HOME_DIR}/.config/sway"
  sed "s|%HOME%|${HOME_DIR}|g" "${SP}/environment.d/90-sweetpotato-csd.conf" \
    > "${HOME_DIR}/.config/environment.d/90-sweetpotato-csd.conf"
  [[ -f "${SP}/sweetlock.png" ]] && \
    cp -f "${SP}/sweetlock.png" "${HOME_DIR}/.local/share/backgrounds/sweetlock.png"
fi

# Skel (no calamares autostart; float rule harmless if installer absent)
sync_common_into "${ISO}/etc/skel"
cp -f "${SP}/swirl/config" "${ISO}/etc/skel/.config/swirl/config"
inject_iso_display "${ISO}/etc/skel/.config/swirl/config"
inject_calamares_float "${ISO}/etc/skel/.config/swirl/config"
inject_iso_display "${ISO}/etc/skel/.config/swirl/config-us"
inject_calamares_float "${ISO}/etc/skel/.config/swirl/config-us"
inject_iso_display "${ISO}/etc/skel/.config/swirl/config-fr"
inject_calamares_float "${ISO}/etc/skel/.config/swirl/config-fr"
cat > "${ISO}/etc/skel/.config/environment.d/90-sweetpotato-csd.conf" << 'EOF'
# Some distros disable GTK CSD via LD_PRELOAD=libgtk-nocsd.so in /etc/environment.
# Clear it so GTK apps keep close buttons. Prefer ~/.local/bin (swirl wrapper).
# Ensure a real PATH so glycin/bwrap can run (Firefox Save As / portal file chooser).
# Note: do not hardcode a username here — skel is copied to each new home.
LD_PRELOAD=
GTK_CSD=1
PATH=/usr/local/bin:/usr/bin:/bin
EOF
cat > "${ISO}/etc/skel/.config/geany/geany.conf" << 'EOF'
[geany]
color_scheme=sweetpotato.conf
show_indent_guide=false
show_white_space=false
pref_main_load_session=false
EOF

# Liveuser (US default + calamares)
sync_common_into "${ISO}/home/liveuser"
cp -f "${SP}/swirl/config-us" "${ISO}/home/liveuser/.config/swirl/config"
inject_iso_display "${ISO}/home/liveuser/.config/swirl/config"
inject_live_calamares "${ISO}/home/liveuser/.config/swirl/config"
inject_iso_display "${ISO}/home/liveuser/.config/swirl/config-us"
inject_live_calamares "${ISO}/home/liveuser/.config/swirl/config-us"
inject_iso_display "${ISO}/home/liveuser/.config/swirl/config-fr"
inject_live_calamares "${ISO}/home/liveuser/.config/swirl/config-fr"
cat > "${ISO}/home/liveuser/.config/environment.d/90-sweetpotato-csd.conf" << 'EOF'
# Some distros disable GTK CSD via LD_PRELOAD=libgtk-nocsd.so in /etc/environment.
# Clear it so GTK apps keep close buttons. Prefer ~/.local/bin (swirl wrapper).
# Ensure a real PATH so glycin/bwrap can run (Firefox Save As / portal file chooser).
LD_PRELOAD=
GTK_CSD=1
PATH=/home/liveuser/.local/bin:/usr/local/bin:/usr/bin:/bin
EOF
cat > "${ISO}/home/liveuser/.config/geany/geany.conf" << 'EOF'
[geany]
color_scheme=sweetpotato.conf
editor_font=Noto Sans Mono 10
show_indent_guide=false
show_white_space=false
show_markers_margin=true
show_linenumber_margin=true
pref_main_load_session=false
EOF
mkdir -p "${ISO}/home/liveuser/Desktop"
# Live session uses empty password; don't block Enter-to-unlock after theme sync
sed -i '/^ignore-empty-password$/d' "${ISO}/home/liveuser/.config/swaylock/config"
if ! grep -q 'Live ISO: liveuser has an empty password' "${ISO}/home/liveuser/.config/swaylock/config"; then
  sed -i '/^show-failed-attempts$/a\
# Live ISO: liveuser has an empty password — allow Enter to unlock.\
# (Installed systems keep ignore-empty-password via skel.)
' "${ISO}/home/liveuser/.config/swaylock/config"
fi

# System logo for fastfetch (absolute path in config.jsonc)
mkdir -p "${ISO}/usr/local/share/sweetpotatos" "${ISO}/etc/fastfetch"
cp -f "${SP}/fastfetch/SPLogo.asc" "${ISO}/usr/local/share/sweetpotatos/SPLogo.asc"
cp -f "${SP}/fastfetch/SPLogo.png" "${ISO}/usr/local/share/sweetpotatos/SPLogo.png"
cp -f "${ISO}/home/liveuser/.config/fastfetch/config.jsonc" "${ISO}/etc/fastfetch/config.jsonc"
# System swirl wrapper (PATH: /usr/local/bin before /usr/bin)
install -Dm755 "${SP}/bin/swirl" "${ISO}/usr/local/bin/swirl"
install -Dm755 "${SP}/bin/sweetpotatos-displays" "${ISO}/usr/local/bin/sweetpotatos-displays"

# System wallpapers (Mod+Shift+w also scans /usr/share/backgrounds)
mkdir -p "${ISO}/usr/share/backgrounds/sweetpotatos"
cp -f "${SP}/backgrounds/"*.png "${ISO}/usr/share/backgrounds/sweetpotatos/"

# Assets
mkdir -p "${ROOT}/assets"
cp -f "${SP}/assets/"*.png "${ROOT}/assets/" 2>/dev/null || true

if command -v swaymsg >/dev/null 2>&1; then
  swaymsg reload >/dev/null 2>&1 || true
fi

if [[ "${SYNC_LIVE}" -eq 1 ]]; then
  echo "Synced SweetPotato → live + SweetPotatOs (skel + liveuser)."
else
  echo "Synced SweetPotato → SweetPotatOs (skel + liveuser). Live \$HOME skipped."
fi
