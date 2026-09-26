#!/usr/bin/env bash
# Tiled terminal cheatsheet (toggle with Mod+?). SPO colors; w → website.
set -euo pipefail

APP_ID="sweetpotato-cheatsheet"
SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
TERM_BIN="${TERM_BIN:-foot}"
SITE_URL="https://sweetpotatos.sourceforge.io/"

PINK=$'\033[1;38;2;167;59;80m'
ORANGE=$'\033[1;38;2;247;155;41m'
CREAM=$'\033[38;2;245;230;232m'
MUTED=$'\033[38;2;170;170;170m'
RESET=$'\033[0m'

if ! command -v "${TERM_BIN}" >/dev/null 2>&1; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "foot not found" 2>/dev/null || true
  exit 1
fi

if [[ ! -f "${SHEET}" ]]; then
  notify-send -a "SweetPotato" -i "help-about" "Cheatsheet" "Missing ${SHEET}" 2>/dev/null || true
  exit 1
fi

# Toggle: second press closes an open sheet.
if swaymsg -t get_tree 2>/dev/null | grep -Fq "\"app_id\": \"${APP_ID}\""; then
  swaymsg "[app_id=\"${APP_ID}\"] kill" >/dev/null 2>&1 || true
  exit 0
fi

export SPO_CHEATSHEET="${SHEET}"
export SPO_SITE_URL="${SITE_URL}"
export SPO_PINK="${PINK}" SPO_ORANGE="${ORANGE}" SPO_CREAM="${CREAM}" SPO_MUTED="${MUTED}" SPO_RESET="${RESET}"

"${TERM_BIN}" -a "${APP_ID}" -T "SweetPotato help" \
  -o colors-dark.background=1d1f21 \
  -o colors-dark.foreground=f5e6e8 \
  -o colors-dark.alpha=1.0 \
  bash -c '
set -euo pipefail
PINK="${SPO_PINK}" ORANGE="${SPO_ORANGE}" CREAM="${SPO_CREAM}" MUTED="${SPO_MUTED}" RESET="${SPO_RESET}"
SHEET="${SPO_CHEATSHEET}"
SITE_URL="${SPO_SITE_URL}"

while IFS= read -r line || [[ -n "${line}" ]]; do
  case "${line}" in
    "  SweetPotato"*)
      printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
    "  Mod = "*)
      printf "%s%s%s\n" "${MUTED}" "${line}" "${RESET}" ;;
    "  Apps"|"  Window / layout"|"  Workspaces / overview"|"  Displays / look"|\
    "  System"|"  Screenshots / media keys"|"  Gestures"|"  Resize mode"*|\
    "  Customize"|"  Desktop / package updates"|"  Project")
      printf "%s%s%s\n" "${ORANGE}" "${line}" "${RESET}" ;;
    "  w  "*|"  sudo sweetpotatos-update"*)
      printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
    "")
      printf "\n" ;;
    *)
      printf "%s%s%s\n" "${CREAM}" "${line}" "${RESET}" ;;
  esac
done < "${SHEET}"
printf "\n%s  w  website · q or Mod+?  close%s\n" "${MUTED}" "${RESET}"

open_site() {
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${SITE_URL}" >/dev/null 2>&1 || true
  elif command -v brave-origin >/dev/null 2>&1; then
    brave-origin "${SITE_URL}" >/dev/null 2>&1 || true
  fi
}

while IFS= read -rsn1 k; do
  case "${k}" in
    q|Q) exit 0 ;;
    w|W) open_site ;;
  esac
done
' &
foot_pid=$!

# Column width on Swirl: set_size (see expand.sh / autotile).
# "Alone" = only one column visible on this output (others may be scrolled off-strip).
export APP_ID
python3 - <<'PY' || true
import json, os, subprocess, time

app_id = os.environ["APP_ID"]

def sway(*args):
    return subprocess.check_output(["swaymsg", *args], text=True)

def sway_cmd(cmd):
    subprocess.run(
        ["swaymsg", cmd],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )

def iter_nodes(node):
    yield node
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key) or []:
            yield from iter_nodes(child)

def find_cheat(tree):
    for n in iter_nodes(tree):
        if n.get("app_id") == app_id:
            return n
    return None

def workspace_of(node, tree):
    target = node["id"]

    def contains(n):
        if n.get("id") == target:
            return True
        for key in ("nodes", "floating_nodes"):
            for c in n.get(key) or []:
                if contains(c):
                    return True
        return False

    for n in iter_nodes(tree):
        if n.get("type") == "workspace" and contains(n):
            return n
    return None

def output_of(workspace, tree):
    wid = workspace["id"]

    def contains(n):
        if n.get("id") == wid:
            return True
        for key in ("nodes", "floating_nodes"):
            for c in n.get(key) or []:
                if contains(c):
                    return True
        return False

    for n in iter_nodes(tree):
        if n.get("type") == "output" and contains(n):
            return n
    return None

def overlaps(a, b):
    ax, aw = (a.get("x") or 0), (a.get("width") or 0)
    bx, bw = (b.get("x") or 0), (b.get("width") or 0)
    return ax < bx + bw and ax + aw > bx

def top_columns(workspace):
    return [n for n in (workspace.get("nodes") or []) if n.get("type") != "floating_con"]

def column_has_view(column):
    for n in iter_nodes(column):
        if n.get("app_id") or n.get("window") or n.get("pid"):
            if n.get("id") != column.get("id"):
                return True
    return False

def first_view_id(column):
    for n in iter_nodes(column):
        if n.get("id") == column.get("id"):
            continue
        if not (n.get("nodes") or []) and (n.get("app_id") or n.get("window") or n.get("pid") or n.get("name")):
            return n["id"]
    return column["id"]

def set_width(con_id, fraction):
    sway_cmd(f"[con_id={con_id}] set_size h {fraction}")

def apply():
    tree = json.loads(sway("-t", "get_tree"))
    cheat = find_cheat(tree)
    if not cheat:
        return False
    ws = workspace_of(cheat, tree)
    if not ws:
        return False
    output = output_of(ws, tree)
    out_rect = (output or {}).get("rect") or ws.get("rect") or {}

    visible = []
    for col in top_columns(ws):
        if not column_has_view(col):
            continue
        if out_rect and not overlaps(col.get("rect") or {}, out_rect):
            continue
        visible.append(col)

    if not visible:
        visible = [c for c in top_columns(ws) if column_has_view(c)]

    if len(visible) <= 1:
        # Full strip — also hit app_id in case con_id targeting races map.
        set_width(cheat["id"], 1.0)
        sway_cmd(f'[app_id="{app_id}"] set_size h 1.0')
        if visible:
            set_width(first_view_id(visible[0]), 1.0)
    else:
        n = len(visible)
        for i, col in enumerate(visible, start=1):
            frac = 1.0 if (n % 2 == 1 and i == n) else 0.5
            set_width(first_view_id(col), frac)
    return True

# Wait for map, then reinforce after autotile (set_size can race view_map).
for _ in range(30):
    if apply():
        break
    time.sleep(0.05)
for delay in (0.15, 0.35, 0.6):
    time.sleep(delay)
    apply()
PY

wait "${foot_pid}"
