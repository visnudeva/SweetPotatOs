#!/usr/bin/env bash
# Apply SweetPotato GTK / icon / cursor theme to all channels apps actually read.
# Prefer Adwaita-dark (ships with GTK — no extra theme package).
# Potato charcoal + accents live in ~/.config/gtk-3.0/gtk.css
# (incl. Thunar multi-select / rubberband — kill Adwaita blue outlines).
set -euo pipefail

pick_gtk_theme() {
  if [[ -n "${THEME:-}" ]]; then
    echo "${THEME}"
    return
  fi
  for candidate in Adwaita-dark Adwaita; do
    if [[ -d "/usr/share/themes/${candidate}" ]] || [[ -d "${HOME}/.themes/${candidate}" ]]; then
      echo "${candidate}"
      return
    fi
  done
  echo "Adwaita-dark"
}

# Ensure user GTK CSS overrides Adwaita blue rubberband / multi-select chrome.
# Full theme lives in gtk.css from skel/ISO; this only backfills on older homes.
ensure_selection_css() {
  local css="${HOME}/.config/gtk-3.0/gtk.css"
  mkdir -p "${HOME}/.config/gtk-3.0"
  if [[ -f "${css}" ]] && grep -q 'Kill Adwaita blue rubberband' "${css}"; then
    return 0
  fi
  cat >> "${css}" << 'EOF'

/* Kill Adwaita blue rubberband / multi-select chrome */
@define-color potato_red #a73b50;
@define-color theme_selected_bg_color #a73b50;
@define-color theme_selected_fg_color #ffffff;
.rubberband,
rubberband,
.content-view rubberband,
.content-view .rubberband,
treeview.view rubberband,
flowbox rubberband,
.thunar .rubberband,
.thunar rubberband {
  border: 1px solid @potato_red;
  background-color: alpha(@potato_red, 0.22);
}
.view.content-view.check:not(list),
iconview.content-view.check:not(list),
.content-view:not(list) check,
.view.content-view.check:checked:not(list),
iconview.content-view.check:checked:not(list),
.content-view:not(list) check:checked {
  background-color: @potato_red;
  color: #ffffff;
}
.thunar .standard-view .view:selected,
.thunar .standard-view .view:selected:focus,
.thunar iconview:selected,
.thunar iconview:selected:focus {
  background-color: alpha(@potato_red, 0.45);
  color: #ffffff;
  outline-color: @potato_red;
  outline-style: solid;
  outline-width: 2px;
  outline-offset: -2px;
  border-color: @potato_red;
  box-shadow: none;
}
EOF
}

THEME="$(pick_gtk_theme)"
ICONS="${ICONS:-Papirus-Dark}"
CURSOR="${CURSOR:-capitaine-cursors}"
FONT="${FONT:-Noto Sans, 10}"

# Prefer installed capitaine variant if needed
if [[ ! -d "/usr/share/icons/${CURSOR}" ]] && [[ ! -d "${HOME}/.icons/${CURSOR}" ]]; then
  if [[ -d /usr/share/icons/capitaine-cursors ]]; then
    CURSOR="capitaine-cursors"
  fi
fi

mkdir -p \
  "${HOME}/.config/gtk-3.0" \
  "${HOME}/.config/gtk-4.0" \
  "${HOME}/.config/xsettingsd"

ensure_selection_css

# settings.ini (used when no settings daemon is running)
for ini in "${HOME}/.config/gtk-3.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"; do
  if [[ -f "${ini}" ]]; then
    sed -i \
      -e "s/^gtk-theme-name=.*/gtk-theme-name=${THEME}/" \
      -e "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=${ICONS}/" \
      -e "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=${CURSOR}/" \
      "${ini}"
  fi
done

# gsettings / dconf (many GTK apps prefer this)
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface gtk-theme "${THEME}" || true
  gsettings set org.gnome.desktop.interface icon-theme "${ICONS}" || true
  gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR}" || true
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
  gsettings set org.gnome.desktop.interface accent-color orange 2>/dev/null || true
fi

# xfconf (Thunar / XFCE apps)
if command -v xfconf-query >/dev/null 2>&1; then
  xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "${THEME}" 2>/dev/null \
    || xfconf-query -c xsettings -p /Net/ThemeName -s "${THEME}" || true
  xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "${ICONS}" 2>/dev/null \
    || xfconf-query -c xsettings -p /Net/IconThemeName -s "${ICONS}" || true
  xfconf-query -c xsettings -p /Gtk/CursorThemeName -n -t string -s "${CURSOR}" 2>/dev/null \
    || xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "${CURSOR}" || true
fi

# xsettingsd (reliable on sway)
cat > "${HOME}/.config/xsettingsd/xsettingsd.conf" << EOF
Net/ThemeName "${THEME}"
Net/IconThemeName "${ICONS}"
Gtk/CursorThemeName "${CURSOR}"
Gtk/CursorThemeSize 24
Gtk/FontName "${FONT}"
Net/EnableEventSounds 0
Net/EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
EOF

if command -v xsettingsd >/dev/null 2>&1; then
  pkill -x xsettingsd 2>/dev/null || true
  sleep 0.2
  xsettingsd >/dev/null 2>&1 &
  disown || true
fi
