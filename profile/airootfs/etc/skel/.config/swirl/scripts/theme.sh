#!/usr/bin/env bash
# Cycle SweetPotato color presets and write them into the desktop configs.
# Dark (charcoal): sweet potato, ube, lime, monochrome.
# Light (off-white): dragon fruit, sweet potato, blueberry, cyberpunk, monochrome.
# Mod+Shift+t next on the current surface. Mod+Ctrl+t switches surface.
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/theme"
ACTIVE_FILE="${STATE_DIR}/active.sh"

DARK_IDS=(sweet-potato ube lime monochrome)
LIGHT_IDS=(dragon-fruit sweet-potato-light blueberry cyberpunk monochrome-light)

QUIET=0
ARGS=()
for arg in "$@"; do
  case "${arg}" in
    --quiet) QUIET=1 ;;
    *) ARGS+=("${arg}") ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

usage() {
  echo "Usage: theme.sh next|prev|toggle|apply|set <id>|preview" >&2
  exit 2
}

rgb_of() {
  local h="$1"
  printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# shellcheck disable=SC2034
load_palette() {
  local id="$1"
  # Optional per-theme overrides. Empty means "use the role default" below.
  BAR_BG=
  BAR_FG=
  BAR_ACCENT=
  BAR_HIGHLIGHT=
  INK_ACCENT=
  INK_HIGHLIGHT=
  EDGE=
  MAKO_BORDER=
  case "${id}" in
    sweet-potato)
      NAME="Sweet potato"; MODE=dark
      SURFACE=1d1f21; RAISED=222426; DEEP=181a1b; VIEW=151617
      HOVER=2c3032; SLIDER=3a3f42; BORDER=2e3234; INACTIVE=3a3a3a
      TEXT=f5e6e8; MUTED=b8a8ab; DIM=888888; INACTIVE_FG=aaaaaa; STRONG=ffffff
      ACCENT=a73b50; HIGHLIGHT=f79b29; ON_ACCENT=ffffff; ON_HIGHLIGHT=1d1f21
      ACCENT_DIM=6e2a38; SUCCESS=c47a3a; SUCCESS_FG=1d1f21
      ADWAITA=orange; SHADE="rgba(0,0,0,0.35)"
      ;;
    ube)
      NAME="Ube"; MODE=dark
      SURFACE=1d1f21; RAISED=222426; DEEP=181a1b; VIEW=181a1b
      HOVER=2c3032; SLIDER=3a3f42; BORDER=2e3234; INACTIVE=3a3a3a
      TEXT=f4f0f8; MUTED=b7a8c4; DIM=888888; INACTIVE_FG=aaaaaa; STRONG=ffffff
      ACCENT=9346c8; HIGHLIGHT=c9a0f5; ON_ACCENT=ffffff; ON_HIGHLIGHT=1d1f21
      ACCENT_DIM=5c3480; SUCCESS=c9a0f5; SUCCESS_FG=1d1f21
      ADWAITA=purple; SHADE="rgba(0,0,0,0.35)"
      ;;
    lime)
      NAME="Lime"; MODE=dark
      SURFACE=1d1f21; RAISED=222426; DEEP=181a1b; VIEW=181a1b
      HOVER=2c3032; SLIDER=3a3f42; BORDER=2e3234; INACTIVE=3a3a3a
      TEXT=f2f6f1; MUTED=a8b5a4; DIM=888888; INACTIVE_FG=aaaaaa; STRONG=ffffff
      ACCENT=2bd45a; HIGHLIGHT=d2ff4a; ON_ACCENT=102414; ON_HIGHLIGHT=1d1f21
      ACCENT_DIM=178a38; SUCCESS=2bd45a; SUCCESS_FG=102414
      ADWAITA=green; SHADE="rgba(0,0,0,0.35)"
      ;;
    monochrome)
      NAME="Monochrome"; MODE=dark
      SURFACE=1d1f21; RAISED=222426; DEEP=181a1b; VIEW=181a1b
      HOVER=2c3032; SLIDER=3a3f42; BORDER=2e3234; INACTIVE=3a3a3a
      TEXT=f2f2f2; MUTED=a3a3a3; DIM=888888; INACTIVE_FG=aaaaaa; STRONG=ffffff
      ACCENT=f2f2f2; HIGHLIGHT=9aa0a6; ON_ACCENT=1d1f21; ON_HIGHLIGHT=1d1f21
      ACCENT_DIM=c8c8c8; SUCCESS=9aa0a6; SUCCESS_FG=1d1f21
      ADWAITA=slate; SHADE="rgba(0,0,0,0.35)"
      ;;
    dragon-fruit)
      NAME="Dragon fruit"; MODE=light
      SURFACE=f4f1ec; RAISED=e8e2d8; DEEP=f4f1ec; VIEW=f4f1ec
      HOVER=e0d9cf; SLIDER=cfc6ba; BORDER=d4cdc2; INACTIVE=c4bdb2
      TEXT=241e20; MUTED=6e6568; DIM=6f675f; INACTIVE_FG=3f3a36; STRONG=241e20
      ACCENT=c2256a; HIGHLIGHT=3a3336; ON_ACCENT=ffffff; ON_HIGHLIGHT=f4f1ec
      ACCENT_DIM=8e1848; SUCCESS=c2256a; SUCCESS_FG=ffffff
      ADWAITA=pink; SHADE="rgba(0,0,0,0.16)"
      ;;
    sweet-potato-light)
      NAME="Sweet potato"; MODE=light
      SURFACE=f4f1ec; RAISED=e8e2d8; DEEP=f4f1ec; VIEW=f4f1ec
      HOVER=e0d9cf; SLIDER=cfc6ba; BORDER=d4cdc2; INACTIVE=c4bdb2
      TEXT=241e20; MUTED=8a5a62; DIM=6f675f; INACTIVE_FG=3f3a36; STRONG=241e20
      ACCENT=a73b50; HIGHLIGHT=f79b29; ON_ACCENT=ffffff; ON_HIGHLIGHT=1d1f21
      ACCENT_DIM=6e2a38; SUCCESS=c47a3a; SUCCESS_FG=1d1f21
      ADWAITA=orange; SHADE="rgba(0,0,0,0.16)"
      ;;
    blueberry)
      NAME="Blueberry"; MODE=light
      SURFACE=f4f1ec; RAISED=e8e2d8; DEEP=f4f1ec; VIEW=f4f1ec
      HOVER=e0d9cf; SLIDER=cfc6ba; BORDER=d4cdc2; INACTIVE=c4bdb2
      TEXT=1c1b19; MUTED=5e6570; DIM=5e6570; INACTIVE_FG=3f3a36; STRONG=1c1b19
      ACCENT=2a3f86; HIGHLIGHT=738bbf; ON_ACCENT=ffffff; ON_HIGHLIGHT=1c1b19
      ACCENT_DIM=1e2e64; SUCCESS=2a3f86; SUCCESS_FG=ffffff
      ADWAITA=blue; SHADE="rgba(0,0,0,0.16)"
      ;;
    monochrome-light)
      NAME="Monochrome"; MODE=light
      SURFACE=f4f1ec; RAISED=e8e2d8; DEEP=f4f1ec; VIEW=f4f1ec
      HOVER=e0d9cf; SLIDER=cfc6ba; BORDER=d4cdc2; INACTIVE=c4bdb2
      TEXT=1d1f21; MUTED=5e646a; DIM=6f675f; INACTIVE_FG=3f3a36; STRONG=1d1f21
      ACCENT=1d1f21; HIGHLIGHT=6e7378; ON_ACCENT=ffffff; ON_HIGHLIGHT=f4f1ec
      ACCENT_DIM=3a3f42; SUCCESS=6e7378; SUCCESS_FG=ffffff
      ADWAITA=slate; SHADE="rgba(0,0,0,0.16)"
      ;;
    cyberpunk)
      # Light paper, neon yellow #ffef00 and blue #51bad9.
      # Those two are too bright to read as text on the paper, so titles,
      # terminal body colors, and thin edges use darker ink of the same hues.
      # The bar is a dark strip: that is where the neon yellow actually shows.
      NAME="Cyberpunk"; MODE=light
      SURFACE=f3f7f8; RAISED=e4eef2; DEEP=f3f7f8; VIEW=f3f7f8
      HOVER=d7e4ea; SLIDER=c3d4dd; BORDER=c5d3db; INACTIVE=b4c6d0
      TEXT=12171a; MUTED=3d5968; DIM=5a7380; INACTIVE_FG=2c414c; STRONG=12171a
      ACCENT=51bad9; HIGHLIGHT=ffef00; ON_ACCENT=12171a; ON_HIGHLIGHT=12171a
      ACCENT_DIM=2f87a6; SUCCESS=51bad9; SUCCESS_FG=12171a
      ADWAITA=yellow; SHADE="rgba(0,0,0,0.16)"
      BAR_BG=12171a
      BAR_FG=f3f7f8
      BAR_ACCENT=ffef00
      BAR_HIGHLIGHT=51bad9
      INK_ACCENT=1f6e86
      INK_HIGHLIGHT=6f6800
      EDGE=1f6e86
      MAKO_BORDER=51bad9
      ;;
    *)
      echo "Unknown theme: ${id}" >&2
      exit 1
      ;;
  esac
  BAR_BG="${BAR_BG:-${SURFACE}}"
  BAR_FG="${BAR_FG:-${STRONG}}"
  BAR_ACCENT="${BAR_ACCENT:-${ACCENT}}"
  BAR_HIGHLIGHT="${BAR_HIGHLIGHT:-${HIGHLIGHT}}"
  INK_ACCENT="${INK_ACCENT:-${ACCENT}}"
  INK_HIGHLIGHT="${INK_HIGHLIGHT:-${HIGHLIGHT}}"
  EDGE="${EDGE:-${ACCENT}}"
  MAKO_BORDER="${MAKO_BORDER:-${HIGHLIGHT}}"
  ID="${id}"
  if [[ "${MODE}" == light ]]; then
    GTK_THEME=Adwaita
    ICONS=Papirus
    # Papirus and Papirus-Dark panel glyphs are light (#dfdfdf).
    # Papirus-Light draws them dark, which matches the bar text.
    TRAY_ICONS=Papirus-Light
    SCHEME=prefer-light
  else
    GTK_THEME=Adwaita-dark
    ICONS=Papirus-Dark
    TRAY_ICONS=Papirus-Dark
    SCHEME=prefer-dark
  fi
  if [[ "${MODE}" == light ]]; then
    MENUBAR="${SURFACE}"
    TUI_TITLE="${INK_ACCENT}"
    TUI_HEADER="${INK_ACCENT}"
    TUI_WARN="${INK_ACCENT}"
  else
    MENUBAR="${RAISED}"
    TUI_TITLE="${HIGHLIGHT}"
    TUI_HEADER="${SUCCESS}"
    TUI_WARN="${HIGHLIGHT}"
  fi
}

canon_id() {
  case "$1" in
    melon) printf '%s\n' sweet-potato-light ;;
    *) printf '%s\n' "$1" ;;
  esac
}

read_state() {
  ID=sweet-potato
  LAST_DARK=sweet-potato
  LAST_LIGHT=dragon-fruit
  if [[ -f "${STATE_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${STATE_FILE}"
    ID="${id:-${ID}}"
    LAST_DARK="${last_dark:-${LAST_DARK}}"
    LAST_LIGHT="${last_light:-${LAST_LIGHT}}"
  fi
  ID="$(canon_id "${ID}")"
  LAST_LIGHT="$(canon_id "${LAST_LIGHT}")"
}

write_state() {
  mkdir -p "${STATE_DIR}"
  cat > "${STATE_FILE}" << EOF
id=${ID}
last_dark=${LAST_DARK}
last_light=${LAST_LIGHT}
EOF
  local accent_rgb highlight_rgb text_rgb muted_rgb
  accent_rgb="$(rgb_of "${ACCENT}")"
  highlight_rgb="$(rgb_of "${HIGHLIGHT}")"
  text_rgb="$(rgb_of "${TEXT}")"
  muted_rgb="$(rgb_of "${MUTED}")"
  cat > "${ACTIVE_FILE}" << EOF
SPO_ID=${ID}
SPO_NAME='${NAME}'
SPO_MODE=${MODE}
SPO_SURFACE=${SURFACE}
SPO_TEXT=${TEXT}
SPO_ACCENT=${ACCENT}
SPO_HIGHLIGHT=${HIGHLIGHT}
SPO_ON_ACCENT=${ON_ACCENT}
SPO_ON_HIGHLIGHT=${ON_HIGHLIGHT}
SPO_MUTED=${MUTED}
SPO_ACCENT_RGB='${accent_rgb}'
SPO_HIGHLIGHT_RGB='${highlight_rgb}'
SPO_TEXT_RGB='${text_rgb}'
SPO_MUTED_RGB='${muted_rgb}'
SPO_GTK_THEME=${GTK_THEME}
SPO_ICONS=${ICONS}
SPO_SCHEME=${SCHEME}
SPO_ADWAITA_ACCENT=${ADWAITA}
EOF
  # Tuber and spore read this on launch. Orange title text disappears on
  # off-white, so light themes use the accent for titles and warnings.
  local tui_muted="${MUTED}"
  if [[ "${ID}" == sweet-potato ]]; then
    tui_muted=8a5a62
  fi
  cat > "${STATE_DIR}/tui-colors" << EOF
title=#${TUI_TITLE}
text=#${TEXT}
muted=#${tui_muted}
header=#${TUI_HEADER}
ok=#${TUI_HEADER}
warn=#${TUI_WARN}
err=#${ACCENT}
sel_bg=#${HIGHLIGHT}
sel_fg=#${ON_HIGHLIGHT}
accent=#${ACCENT}
highlight=#${HIGHLIGHT}
EOF
}

replace_block() {
  local file="$1" start="$2" end="$3" tmp
  [[ -f "${file}" ]] || return 0
  tmp="$(mktemp)"
  cat > "${tmp}"
  python3 - "${file}" "${start}" "${end}" "${tmp}" << 'PY'
import pathlib, sys
path, start, end, payload_path = sys.argv[1:]
file = pathlib.Path(path)
text = file.read_text()
payload = pathlib.Path(payload_path).read_text().strip("\n")
i = text.find(start)
if i < 0:
    raise SystemExit(f"missing {start} in {path}")
j = text.find(end, i + len(start))
if j < 0:
    raise SystemExit(f"missing {end} in {path}")
# Keep the end marker's own indent. find() lands on the marker text,
# which drops leading spaces on that line.
line_start = text.rfind("\n", i, j) + 1
new = text[: i + len(start)] + "\n" + payload + "\n" + text[line_start:]
if new != text:
    file.write_text(new)
    print("changed")
PY
  rm -f "${tmp}"
}

note_change() {
  if grep -q changed; then
    CHANGED=1
  fi
}

write_configs() {
  local payload changed_note
  CHANGED=0

  payload="$(mktemp)"
  cat > "${payload}" << EOF
client.focused           #${EDGE} #${SURFACE} #${STRONG} #${ACCENT} #${EDGE}
client.focused_inactive  #${INACTIVE} #${SURFACE} #${INACTIVE_FG} #${INACTIVE} #${INACTIVE}
client.unfocused         #${INACTIVE} #${SURFACE} #${DIM} #${INACTIVE} #${INACTIVE}
client.urgent            #${HIGHLIGHT} #${HIGHLIGHT} #${ON_HIGHLIGHT} #${ACCENT} #${HIGHLIGHT}
client.placeholder       #${SURFACE} #${SURFACE} #${DIM} #${SURFACE} #${SURFACE}
client.background        #${SURFACE}
# Sticky / pinned / selection (Swirl defaults are blue — match the accent)
client.sticky            #${EDGE} #${SURFACE} #${STRONG} #${ACCENT} #${EDGE}
client.sticky_focused    #${EDGE} #${SURFACE} #${STRONG} #${ACCENT} #${EDGE}
client.pinned            #${INACTIVE} #${SURFACE} #${INACTIVE_FG} #${ACCENT} #${INACTIVE}
client.pinned_focused    #${EDGE} #${SURFACE} #${STRONG} #${ACCENT} #${EDGE}
client.selected          #${INK_HIGHLIGHT} #${SURFACE} #${STRONG} #${HIGHLIGHT} #${INK_HIGHLIGHT}
client.selected_focused  #${EDGE} #${SURFACE} #${STRONG} #${ACCENT} #${EDGE}
EOF
  local cfg
  for cfg in "${ROOT}/swirl/config" "${ROOT}/swirl/config-us" "${ROOT}/swirl/config-fr"; do
    [[ -f "${cfg}" ]] || continue
    changed_note="$(replace_block "${cfg}" "# SPO-CLIENT-START" "# SPO-CLIENT-END" < "${payload}")"
    note_change <<< "${changed_note}"
    if grep -q 'icon_theme ' "${cfg}"; then
      local icon_line="    icon_theme ${TRAY_ICONS}"
      if ! grep -qx "${icon_line}" "${cfg}"; then
        sed -i "s/^[[:space:]]*icon_theme .*/${icon_line}/" "${cfg}"
        CHANGED=1
      fi
    fi
  done
  rm -f "${payload}"

  payload="$(mktemp)"
  cat > "${payload}" << EOF
        statusline #${BAR_FG}
        background #${BAR_BG}
        separator  #${BAR_ACCENT}

        # Border and fill match the bar, so each workspace is only a disc.
        # Unselected uses the highlight; the selected one uses the accent.
        focused_workspace     #${BAR_BG} #${BAR_BG} #${BAR_ACCENT}
        active_workspace      #${BAR_BG} #${BAR_BG} #${BAR_HIGHLIGHT}
        inactive_workspace    #${BAR_BG} #${BAR_BG} #${BAR_HIGHLIGHT}
        urgent_workspace      #${BAR_BG} #${BAR_BG} #${BAR_FG}
        binding_mode          #${HIGHLIGHT} #${HIGHLIGHT} #${ON_HIGHLIGHT}
EOF
  for cfg in "${ROOT}/swirl/config" "${ROOT}/swirl/config-us" "${ROOT}/swirl/config-fr"; do
    [[ -f "${cfg}" ]] || continue
    changed_note="$(replace_block "${cfg}" "# SPO-BAR-START" "# SPO-BAR-END" < "${payload}")"
    note_change <<< "${changed_note}"
  done
  rm -f "${payload}"

  if [[ -f "${ROOT}/foot/foot.ini" ]]; then
    payload="$(mktemp)"
    if [[ "${ID}" == sweet-potato ]]; then
      cat > "${payload}" << 'EOF'
[colors-dark]
alpha=1.0
foreground=f5e6e8
background=1d1f21
regular0=1d1f21
regular1=a73b50
regular2=c47a3a
regular3=f79b29
regular4=8a5a62
regular5=c45c72
regular6=d4894a
regular7=f5e6e8
bright0=5a5a5a
bright1=c45c72
bright2=e09a5a
bright3=ffb84d
bright4=a73b50
bright5=e07088
bright6=f79b29
bright7=ffffff

selection-foreground=1d1f21
selection-background=f79b29

urls=f79b29

[colors-light]
alpha=1.0
foreground=f5e6e8
background=1d1f21
regular0=1d1f21
regular1=a73b50
regular2=c47a3a
regular3=f79b29
regular4=8a5a62
regular5=c45c72
regular6=d4894a
regular7=f5e6e8
bright0=5a5a5a
bright1=c45c72
bright2=e09a5a
bright3=ffb84d
bright4=a73b50
bright5=e07088
bright6=f79b29
bright7=ffffff

selection-foreground=1d1f21
selection-background=f79b29

urls=f79b29
EOF
    elif [[ "${ID}" == cyberpunk ]]; then
      cat > "${payload}" << 'EOF'
[colors-dark]
alpha=1.0
foreground=12171a
background=f3f7f8
regular0=12171a
regular1=b4234a
regular2=1f6e86
regular3=6f6800
regular4=3d5968
regular5=1f6e86
regular6=1f6e86
regular7=12171a
bright0=5a7380
bright1=51bad9
bright2=51bad9
bright3=ffef00
bright4=51bad9
bright5=7fd4ea
bright6=ffef00
bright7=ffffff

selection-foreground=12171a
selection-background=ffef00

urls=1f6e86

[colors-light]
alpha=1.0
foreground=12171a
background=f3f7f8
regular0=12171a
regular1=b4234a
regular2=1f6e86
regular3=6f6800
regular4=3d5968
regular5=1f6e86
regular6=1f6e86
regular7=12171a
bright0=5a7380
bright1=51bad9
bright2=51bad9
bright3=ffef00
bright4=51bad9
bright5=7fd4ea
bright6=ffef00
bright7=ffffff

selection-foreground=12171a
selection-background=ffef00

urls=1f6e86
EOF
    else
      cat > "${payload}" << EOF
[colors-dark]
alpha=1.0
foreground=${TEXT}
background=${SURFACE}
regular0=${SURFACE}
regular1=${INK_ACCENT}
regular2=${INK_HIGHLIGHT}
regular3=${INK_HIGHLIGHT}
regular4=${MUTED}
regular5=${INK_ACCENT}
regular6=${INK_HIGHLIGHT}
regular7=${TEXT}
bright0=${INACTIVE}
bright1=${ACCENT}
bright2=${HIGHLIGHT}
bright3=${HIGHLIGHT}
bright4=${ACCENT}
bright5=${ACCENT}
bright6=${HIGHLIGHT}
bright7=${STRONG}

selection-foreground=${ON_HIGHLIGHT}
selection-background=${HIGHLIGHT}

urls=${INK_HIGHLIGHT}

[colors-light]
alpha=1.0
foreground=${TEXT}
background=${SURFACE}
regular0=${SURFACE}
regular1=${INK_ACCENT}
regular2=${INK_HIGHLIGHT}
regular3=${INK_HIGHLIGHT}
regular4=${MUTED}
regular5=${INK_ACCENT}
regular6=${INK_HIGHLIGHT}
regular7=${TEXT}
bright0=${INACTIVE}
bright1=${ACCENT}
bright2=${HIGHLIGHT}
bright3=${HIGHLIGHT}
bright4=${ACCENT}
bright5=${ACCENT}
bright6=${HIGHLIGHT}
bright7=${STRONG}

selection-foreground=${ON_HIGHLIGHT}
selection-background=${HIGHLIGHT}

urls=${INK_HIGHLIGHT}
EOF
    fi
    changed_note="$(replace_block "${ROOT}/foot/foot.ini" "# SPO-THEME-START" "# SPO-THEME-END" < "${payload}")"
    note_change <<< "${changed_note}"
    rm -f "${payload}"
  fi

  if [[ -f "${ROOT}/mako/config" ]]; then
    changed_note="$(replace_block "${ROOT}/mako/config" "# SPO-THEME-START" "# SPO-THEME-END" << EOF
background-color=#${SURFACE}ee
text-color=#${TEXT}ff
border-color=#${MAKO_BORDER}ff
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/mako/config" "# SPO-PROGRESS-START" "# SPO-PROGRESS-END" << EOF
progress-color=over #${ACCENT}ff
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/mako/config" "# SPO-LOW-START" "# SPO-LOW-END" << EOF
border-color=#${INACTIVE}ff
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/mako/config" "# SPO-NORMAL-START" "# SPO-NORMAL-END" << EOF
border-color=#${MAKO_BORDER}ff
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/mako/config" "# SPO-CRITICAL-START" "# SPO-CRITICAL-END" << EOF
background-color=#${SURFACE}ff
border-color=#${ACCENT}ff
text-color=#${STRONG}ff
EOF
)"
    note_change <<< "${changed_note}"
  fi

  if [[ -f "${ROOT}/swaylock/config" ]]; then
    changed_note="$(replace_block "${ROOT}/swaylock/config" "# SPO-THEME-START" "# SPO-THEME-END" << EOF
color=${SURFACE}
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/swaylock/config" "# SPO-LOCK-START" "# SPO-LOCK-END" << EOF
inside-color=${HIGHLIGHT}ff
inside-clear-color=${HIGHLIGHT}ff
inside-ver-color=${HIGHLIGHT}ff
inside-wrong-color=${HIGHLIGHT}ff
inside-caps-lock-color=${HIGHLIGHT}ff

ring-color=${ACCENT}ff
ring-clear-color=${ACCENT}ff
ring-ver-color=${ACCENT}ff
ring-wrong-color=${ACCENT}ff
ring-caps-lock-color=${ACCENT}ff

key-hl-color=${HIGHLIGHT}ff
bs-hl-color=${ACCENT}ff
caps-lock-key-hl-color=${HIGHLIGHT}ff
caps-lock-bs-hl-color=${ACCENT}ff
EOF
)"
    note_change <<< "${changed_note}"
    changed_note="$(replace_block "${ROOT}/swaylock/config" "# SPO-TEXT-START" "# SPO-TEXT-END" << EOF
text-color=${INK_ACCENT}ff
text-clear-color=${INK_ACCENT}ff
text-ver-color=${INK_ACCENT}ff
text-wrong-color=${INK_ACCENT}ff
text-caps-lock-color=${INK_ACCENT}ff

layout-bg-color=${SURFACE}cc
layout-border-color=${ACCENT}ff
layout-text-color=${STRONG}ff
EOF
)"
    note_change <<< "${changed_note}"
  fi

  if [[ -f "${ROOT}/fastfetch/config.jsonc" ]]; then
    changed_note="$(python3 - "${ROOT}/fastfetch/config.jsonc" "${INK_ACCENT}" "${INK_HIGHLIGHT}" << 'PY'
import pathlib, re, sys
path, accent, highlight = sys.argv[1:]
file = pathlib.Path(path)
text = file.read_text()
new = re.sub(r'("keys":\s*")#[0-9A-Fa-f]+', rf'\1#{accent}', text, count=1)
new = re.sub(r'("title":\s*")#[0-9A-Fa-f]+', rf'\1#{highlight}', new, count=1)
if new != text:
    file.write_text(new)
    print("changed")
PY
)"
    note_change <<< "${changed_note}"
  fi

  if [[ -f "${ROOT}/networkmanager-dmenu/config.ini" ]]; then
    changed_note="$(python3 - "${ROOT}/networkmanager-dmenu/config.ini" \
      "${SURFACE}" "${TEXT}" "${ACCENT}" "${ON_ACCENT}" "${HIGHLIGHT}" "${ON_HIGHLIGHT}" << 'PY'
import pathlib, sys
path, surface, text, accent, on_accent, highlight, on_highlight = sys.argv[1:]
file = pathlib.Path(path)
src = file.read_text().splitlines(keepends=True)
out = []
cmd = (
    'dmenu_command = wmenu -i -f "Noto Sans 11" '
    f'-N {surface}ff -n {text}ff -M {accent}ff -m {on_accent}ff '
    f'-S {highlight}ff -s {on_highlight}ff\n'
)
for line in src:
    if line.startswith("dmenu_command ="):
        line = cmd
    elif line.startswith("obscure_color"):
        line = f"obscure_color = #{surface}\n"
    out.append(line)
new = "".join(out)
old = "".join(src)
if new != old:
    file.write_text(new)
    print("changed")
PY
)"
    note_change <<< "${changed_note}"
  fi

  if [[ -f "${ROOT}/gtk-3.0/gtk.css" ]]; then
    local gtk_accent="@potato_orange"
    if [[ "${INK_HIGHLIGHT}" != "${HIGHLIGHT}" ]]; then
      gtk_accent="#${INK_HIGHLIGHT}"
    fi
    changed_note="$(replace_block "${ROOT}/gtk-3.0/gtk.css" "/* SPO-THEME-START */" "/* SPO-THEME-END */" << EOF
/* ${NAME} — ${MODE} */
@define-color potato_red #${ACCENT};
@define-color potato_orange #${HIGHLIGHT};
@define-color potato_charcoal #${SURFACE};
@define-color potato_chrome #${RAISED};
@define-color potato_panel #${DEEP};
@define-color potato_fg #${TEXT};
@define-color potato_muted #${MUTED};
@define-color potato_hover #${HOVER};
@define-color potato_slider #${SLIDER};
@define-color potato_menubar #${MENUBAR};

@define-color theme_bg_color @potato_charcoal;
@define-color theme_fg_color @potato_fg;
@define-color theme_base_color @potato_panel;
@define-color theme_text_color @potato_fg;
@define-color theme_selected_bg_color #${ACCENT};
@define-color theme_selected_fg_color #${ON_ACCENT};
@define-color accent_color ${gtk_accent};
@define-color accent_bg_color @potato_red;
@define-color accent_fg_color #${ON_ACCENT};
@define-color theme_selected_bg_color_backdrop #${ACCENT_DIM};
@define-color insensitive_bg_color @potato_chrome;
@define-color insensitive_fg_color @potato_muted;
@define-color borders_color #${BORDER};
@define-color theme_unfocused_bg_color @potato_charcoal;
@define-color theme_unfocused_fg_color @potato_muted;
@define-color theme_unfocused_base_color @potato_panel;
@define-color theme_unfocused_text_color @potato_muted;
@define-color theme_unfocused_selected_bg_color #${ACCENT_DIM};
@define-color theme_unfocused_selected_fg_color #${ON_ACCENT};
EOF
)"
    note_change <<< "${changed_note}"
  fi

  if [[ -f "${ROOT}/gtk-4.0/gtk.css" ]]; then
    changed_note="$(replace_block "${ROOT}/gtk-4.0/gtk.css" "/* SPO-THEME-START */" "/* SPO-THEME-END */" << EOF
/* ${NAME} — ${MODE} */
@define-color window_bg_color #${SURFACE};
@define-color window_fg_color #${TEXT};
@define-color view_bg_color #${VIEW};
@define-color view_fg_color #${TEXT};
@define-color headerbar_bg_color #${RAISED};
@define-color headerbar_fg_color #${TEXT};
@define-color accent_bg_color #${ACCENT};
@define-color accent_fg_color #${ON_ACCENT};
@define-color accent_color #${INK_HIGHLIGHT};
@define-color destructive_bg_color #7a2030;
@define-color destructive_fg_color #ffffff;
@define-color success_bg_color #${SUCCESS};
@define-color success_fg_color #${SUCCESS_FG};
@define-color warning_bg_color #${HIGHLIGHT};
@define-color warning_fg_color #${ON_HIGHLIGHT};
@define-color error_bg_color #${ACCENT};
@define-color error_fg_color #${ON_ACCENT};
@define-color card_bg_color #${RAISED};
@define-color card_fg_color #${TEXT};
@define-color popover_bg_color #${RAISED};
@define-color popover_fg_color #${TEXT};
@define-color shade_color ${SHADE};
@define-color sidebar_bg_color #${RAISED};
@define-color sidebar_fg_color #${TEXT};
@define-color secondary_sidebar_bg_color #${SURFACE};
@define-color secondary_sidebar_fg_color #${TEXT};
EOF
)"
    note_change <<< "${changed_note}"
  fi
}

cycle() {
  local dir="$1"
  local -a group
  if [[ "${MODE}" == light ]]; then
    group=("${LIGHT_IDS[@]}")
  else
    group=("${DARK_IDS[@]}")
  fi
  local i n=0 found=0
  for i in "${!group[@]}"; do
    if [[ "${group[$i]}" == "${ID}" ]]; then
      found=1
      n="${i}"
      break
    fi
  done
  if [[ "${found}" -eq 0 ]]; then
    n=0
  elif [[ "${dir}" == next ]]; then
    n=$(( (n + 1) % ${#group[@]} ))
  else
    n=$(( (n + ${#group[@]} - 1) % ${#group[@]} ))
  fi
  ID="${group[$n]}"
}

remember_side() {
  if [[ "${MODE}" == light ]]; then
    LAST_LIGHT="${ID}"
  else
    LAST_DARK="${ID}"
  fi
}

apply_current() {
  load_palette "${ID}"
  remember_side
  write_state
  write_configs
}

reload_desktop() {
  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    swaymsg reload >/dev/null 2>&1 || true
  fi
  if command -v makoctl >/dev/null 2>&1; then
    makoctl reload >/dev/null 2>&1 || true
  fi
  if [[ "${QUIET}" -eq 0 ]] && command -v notify-send >/dev/null 2>&1; then
    notify-send -a "SweetPotato" "Theme" "${NAME}" >/dev/null 2>&1 || true
  fi
}

preview() {
  local out="${SPO_PREVIEW:-/tmp/sweetpotato-themes.png}"
  python3 - "${out}" << 'PY'
import struct, zlib, sys
out = sys.argv[1]
themes = [
    ("Sweet potato", "1d1f21", "f5e6e8", "a73b50", "f79b29"),
    ("Ube", "1d1f21", "f4f0f8", "9346c8", "c9a0f5"),
    ("Lime", "1d1f21", "f2f6f1", "2bd45a", "d2ff4a"),
    ("Monochrome", "1d1f21", "f2f2f2", "f2f2f2", "9aa0a6"),
    ("Dragon fruit", "f4f1ec", "241e20", "c2256a", "3a3336"),
    ("Sweet potato", "f4f1ec", "241e20", "a73b50", "f79b29"),
    ("Blueberry", "f4f1ec", "1c1b19", "2a3f86", "738bbf"),
    ("Cyberpunk", "f3f7f8", "12171a", "51bad9", "ffef00"),
    ("Monochrome", "f4f1ec", "1d1f21", "1d1f21", "6e7378"),
]
def rgb(h):
    return bytes(int(h[i:i+2], 16) for i in (0, 2, 4))
w, row_h, label_w, sw = 920, 72, 180, 140
h = row_h * len(themes)
rows = []
for name, surface, text, accent, highlight in themes:
    row = bytearray()
    for _y in range(row_h):
        row += b"\x00"
        for x in range(w):
            if x < label_w:
                color = surface
            elif x < label_w + sw:
                color = accent
            elif x < label_w + sw * 2:
                color = highlight
            else:
                color = surface
            row += rgb(color)
    rows.append(row)
raw = b"".join(rows)
def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw, 9))
png += chunk(b"IEND", b"")
open(out, "wb").write(png)
print(out)
PY
}

cmd="${1:-}"
case "${cmd}" in
  preview)
    preview
    ;;
  apply)
    read_state
    apply_current
    if [[ "${CHANGED}" -eq 1 && -n "${SWAYSOCK:-}" ]]; then
      reload_desktop
    fi
    [[ "${QUIET}" -eq 1 ]] || echo "${NAME}"
    ;;
  next|prev)
    read_state
    load_palette "${ID}"
    cycle "${cmd}"
    apply_current
    reload_desktop
    [[ "${QUIET}" -eq 1 ]] || echo "${NAME}"
    ;;
  toggle)
    read_state
    load_palette "${ID}"
    remember_side
    if [[ "${MODE}" == light ]]; then
      ID="${LAST_DARK}"
    else
      ID="${LAST_LIGHT}"
    fi
    apply_current
    reload_desktop
    [[ "${QUIET}" -eq 1 ]] || echo "${NAME}"
    ;;
  set)
    [[ -n "${2:-}" ]] || usage
    read_state
    ID="$(canon_id "$2")"
    apply_current
    reload_desktop
    [[ "${QUIET}" -eq 1 ]] || echo "${NAME}"
    ;;
  *)
    usage
    ;;
esac
