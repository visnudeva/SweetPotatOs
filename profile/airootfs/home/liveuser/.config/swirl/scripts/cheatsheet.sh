#!/usr/bin/env bash
# Tiled terminal cheatsheet (toggle with Mod+?). SPO colors; w → website.
# Opens on workspace "spo-help" so Swirl autotile gives a full-width column;
# closing returns to the previous workspace.
set -euo pipefail

APP_ID="sweetpotato-cheatsheet"
HELP_WS="spo-help"
SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
TERM_BIN="${TERM_BIN:-foot}"
SITE_URL="https://sweetpotatos.sourceforge.io/"
STATE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-cheatsheet-ws"

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

restore_ws() {
  if [[ -f "${STATE}" ]]; then
    prev="$(cat "${STATE}" 2>/dev/null || true)"
    rm -f "${STATE}"
    if [[ -n "${prev}" ]]; then
      swaymsg "workspace ${prev}" >/dev/null 2>&1 || true
    fi
  fi
}

# Toggle: second press closes and returns to the previous workspace.
if swaymsg -t get_tree 2>/dev/null | grep -Fq "\"app_id\": \"${APP_ID}\""; then
  swaymsg "[app_id=\"${APP_ID}\"] kill" >/dev/null 2>&1 || true
  restore_ws
  exit 0
fi

# Remember where we were, then open help alone on its own workspace (full width).
prev_ws="$(
  swaymsg -t get_workspaces 2>/dev/null \
    | python3 -c 'import json,sys; ws=json.load(sys.stdin); print(next((w["name"] for w in ws if w.get("focused")),""))' \
    2>/dev/null || true
)"
printf '%s\n' "${prev_ws}" >"${STATE}"
swaymsg "workspace ${HELP_WS}" >/dev/null 2>&1 || true

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

# Alone on spo-help → force full column (same IPC as Mod+m / autotile).
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

def force_full():
    tree = json.loads(sway("-t", "get_tree"))
    cheat = find_cheat(tree)
    if not cheat:
        return False
    sway_cmd(f'[app_id="{app_id}"] focus')
    sway_cmd(f'[app_id="{app_id}"] set_size h 1.0')
    sway_cmd(f'[con_id={cheat["id"]}] set_size h 1.0')
    return True

for _ in range(40):
    if force_full():
        break
    time.sleep(0.05)
for _ in range(8):
    time.sleep(0.15)
    force_full()
PY

wait "${foot_pid}" || true
restore_ws
