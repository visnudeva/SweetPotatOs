#!/usr/bin/env bash
# Floating terminal cheatsheet (toggle with Mod+?). SPO colors; w → website.
# x, while this page is focused, turns the keybind reminder on or off.
# Uses less so the sheet opens at the top (not scrolled to the bottom).
# Website key is a temporary Swirl bind while this window is focused — less's
# "shell" action always shows "!done (press RETURN)" and dumps browser stderr.
set -euo pipefail

APP_ID="sweetpotato-cheatsheet"
SHEET="${XDG_CONFIG_HOME:-${HOME}/.config}/swirl/cheatsheet.txt"
TERM_BIN="${TERM_BIN:-foot}"
SITE_URL="https://sweetpotatos.sourceforge.io/"

ACTIVE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/active.sh"
if [[ -f "${ACTIVE}" ]]; then
  # shellcheck disable=SC1090
  source "${ACTIVE}"
fi
: "${SPO_ACCENT_RGB:=167;59;80}"
: "${SPO_HIGHLIGHT_RGB:=247;155;41}"
: "${SPO_TEXT_RGB:=245;230;232}"
: "${SPO_MUTED_RGB:=170;170;170}"
: "${SPO_SURFACE:=1d1f21}"
: "${SPO_TEXT:=f5e6e8}"
PINK=$'\033[1;38;2;'"${SPO_ACCENT_RGB}"'m'
ORANGE=$'\033[1;38;2;'"${SPO_HIGHLIGHT_RGB}"'m'
CREAM=$'\033[38;2;'"${SPO_TEXT_RGB}"'m'
MUTED=$'\033[38;2;'"${SPO_MUTED_RGB}"'m'
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
export SPO_APP_ID="${APP_ID}"
export SPO_PINK="${PINK}" SPO_ORANGE="${ORANGE}" SPO_CREAM="${CREAM}" SPO_MUTED="${MUTED}" SPO_RESET="${RESET}"

# Swallow w/x in foot so they never type into less if the compositor bind
# is late or the key still reaches the terminal. Swirl still runs the binds.
exec "${TERM_BIN}" -a "${APP_ID}" -T "SweetPotato help" \
  -o colors-dark.background="${SPO_SURFACE}" \
  -o colors-dark.foreground="${SPO_TEXT}" \
  -o colors-dark.alpha=1.0 \
  -o "key-bindings.noop=x X w W" \
  bash -c '
set -euo pipefail
PINK="${SPO_PINK}" ORANGE="${SPO_ORANGE}" CREAM="${SPO_CREAM}" MUTED="${SPO_MUTED}" RESET="${SPO_RESET}"
SHEET="${SPO_CHEATSHEET}"
SITE_URL="${SPO_SITE_URL}"
APP_ID="${SPO_APP_ID}"
TIP_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/login-tip"
TTY_PATH="$(tty 2>/dev/null || true)"

content="$(mktemp)"
opener="$(mktemp)"
toggler="$(mktemp)"
restart_flag="$(mktemp)"
less_pid_file="$(mktemp)"
rm -f "${restart_flag}"
fifo="$(mktemp -u)"
mkfifo "${fifo}"
exec 3<>"${fifo}"
watch_pid=""
tip_pid=""

tip_state() {
  local s=on
  if [[ -f "${TIP_FILE}" ]]; then
    s="$(tr -d "[:space:]" < "${TIP_FILE}" || true)"
  fi
  if [[ "${s}" == off ]]; then
    printf "%s" off
  else
    printf "%s" on
  fi
}

cleanup() {
  if [[ -n "${watch_pid}" ]]; then
    kill "${watch_pid}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${tip_pid}" ]]; then
    kill "${tip_pid}" >/dev/null 2>&1 || true
  fi
  if [[ -f "${less_pid_file}" ]]; then
    lp="$(cat "${less_pid_file}" 2>/dev/null || true)"
    if [[ -n "${lp}" ]]; then
      kill "${lp}" >/dev/null 2>&1 || true
    fi
  fi
  swaymsg unbindsym w >/dev/null 2>&1 || true
  swaymsg unbindsym Shift+w >/dev/null 2>&1 || true
  swaymsg unbindsym x >/dev/null 2>&1 || true
  swaymsg unbindsym Shift+x >/dev/null 2>&1 || true
  rm -f "${content}" "${opener}" "${toggler}" "${fifo}" "${restart_flag}" "${less_pid_file}"
}
trap cleanup EXIT

render_content() {
  local state line
  state="$(tip_state)"
  {
    while IFS= read -r line || [[ -n "${line}" ]]; do
      case "${line}" in
        "  SweetPotato"*)
          printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
        "  Mod = "*)
          printf "%s%s%s\n" "${MUTED}" "${line}" "${RESET}" ;;
        "  Apps"|"  Window / layout"|"  Workspaces / overview"|"  Displays / look"|\
        "  System"|"  Screenshots / media keys"|"  Gestures"|"  Resize mode"*|\
        "  Customize"|"  Desktop / package updates"|"  Project"|"  This page")
          printf "%s%s%s\n" "${ORANGE}" "${line}" "${RESET}" ;;
        *"Keybind reminder"*)
          if [[ "${state}" == off ]]; then
            printf "%s  x%s %sKeybind reminder       off%s\n" "${PINK}" "${RESET}" "${CREAM}" "${RESET}"
            printf "%s                       Press x to show it at login again%s\n" "${MUTED}" "${RESET}"
          else
            printf "%s  x%s %sKeybind reminder       on%s\n" "${PINK}" "${RESET}" "${CREAM}" "${RESET}"
            printf "%s                       Press x to hide the keybind reminder%s\n" "${MUTED}" "${RESET}"
          fi
          ;;
        "  w  "*|"  sudo sweetpotatos-update"*)
          printf "%s%s%s\n" "${PINK}" "${line}" "${RESET}" ;;
        "")
          printf "\n" ;;
        *)
          printf "%s%s%s\n" "${CREAM}" "${line}" "${RESET}" ;;
      esac
    done < "${SHEET}"
  } >"${content}"
}

# On x: rewrite the sheet and restart less. Do not type into less (that left
# garbage like eWQ on the page when :e was injected).
(
  while IFS= read -r cmd <&3; do
    [[ "${cmd}" == toggle ]] || continue
    render_content || true
    : > "${restart_flag}"
    if [[ -f "${less_pid_file}" ]]; then
      lp="$(cat "${less_pid_file}" 2>/dev/null || true)"
      if [[ -n "${lp}" ]]; then
        kill "${lp}" >/dev/null 2>&1 || true
      fi
    fi
  done
) &
tip_pid=$!

# Opener: only acts when the cheatsheet is focused (bind is otherwise inactive).
cat >"${opener}" <<EOF
#!/bin/bash
set -euo pipefail
APP_ID=$(printf '%q' "${APP_ID}")
SITE_URL=$(printf '%q' "${SITE_URL}")
focused="\$(swaymsg -t get_tree 2>/dev/null | python3 -c "
import json, sys
def walk(n):
    if n.get(\"focused\"):
        return n.get(\"app_id\") or \"\"
    for key in (\"nodes\", \"floating_nodes\"):
        for c in n.get(key) or []:
            r = walk(c)
            if r is not None:
                return r
    return None
print(walk(json.load(sys.stdin)) or \"\")
" 2>/dev/null || true)"
[[ "\${focused}" == "\${APP_ID}" ]] || exit 0
setsid xdg-open "\${SITE_URL}" </dev/null >/dev/null 2>&1 &
EOF
chmod 755 "${opener}"

cat >"${toggler}" <<EOF
#!/bin/bash
set -euo pipefail
APP_ID=$(printf "%q" "${APP_ID}")
TIP_FILE=$(printf "%q" "${TIP_FILE}")
FIFO=$(printf "%q" "${fifo}")
focused="\$(swaymsg -t get_tree 2>/dev/null | python3 -c "
import json, sys
def walk(n):
    if n.get(\"focused\"):
        return n.get(\"app_id\") or \"\"
    for key in (\"nodes\", \"floating_nodes\"):
        for c in n.get(key) or []:
            r = walk(c)
            if r is not None:
                return r
    return None
print(walk(json.load(sys.stdin)) or \"\")
" 2>/dev/null || true)"
[[ "\${focused}" == "\${APP_ID}" ]] || exit 0
state="\$(tr -d "[:space:]" < "\${TIP_FILE}" 2>/dev/null || true)"
mkdir -p "\$(dirname "\${TIP_FILE}")"
if [[ "\${state}" == off ]]; then
  printf "on\n" > "\${TIP_FILE}"
  notify-send -t 4000 -a "SweetPotato" -i "help-about" \
    -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
    "Keybind reminder on" "It will show again the next time you log in." \
    >/dev/null 2>&1 || true
else
  printf "off\n" > "\${TIP_FILE}"
  notify-send -t 4000 -a "SweetPotato" -i "help-about" \
    -h "string:x-canonical-private-synchronous:sweetpotato-tips" \
    "Keybind reminder off" "It will not show at login. Press x here to turn it back on." \
    >/dev/null 2>&1 || true
fi
printf "toggle\n" > "\${FIFO}"
EOF
chmod 755 "${toggler}"

cheat_focused() {
  local focused
  focused="$(swaymsg -t get_tree 2>/dev/null | python3 -c "
import json, sys
def walk(n):
    if n.get(\"focused\"):
        return n.get(\"app_id\") or \"\"
    for key in (\"nodes\", \"floating_nodes\"):
        for c in n.get(key) or []:
            r = walk(c)
            if r is not None:
                return r
    return None
print(walk(json.load(sys.stdin)) or \"\")
" 2>/dev/null || true)"
  [[ "${focused}" == "${APP_ID}" ]]
}

# Bind w only while this sheet is focused so other apps keep their w key.
(
  local_bound=0
  while true; do
    if cheat_focused; then
      if ((local_bound == 0)); then
        swaymsg "bindsym --no-warn w exec ${opener}" >/dev/null 2>&1 || true
        swaymsg "bindsym --no-warn Shift+w exec ${opener}" >/dev/null 2>&1 || true
        swaymsg "bindsym --no-warn x exec ${toggler}" >/dev/null 2>&1 || true
        swaymsg "bindsym --no-warn Shift+x exec ${toggler}" >/dev/null 2>&1 || true
        local_bound=1
      fi
    else
      if ((local_bound == 1)); then
        swaymsg unbindsym w >/dev/null 2>&1 || true
        swaymsg unbindsym Shift+w >/dev/null 2>&1 || true
        swaymsg unbindsym x >/dev/null 2>&1 || true
        swaymsg unbindsym Shift+x >/dev/null 2>&1 || true
        local_bound=0
      fi
    fi
    sleep 0.2
  done
) &
watch_pid=$!

status="${PINK}w${RESET} ${CREAM}website${RESET}  ${PINK}x${RESET} ${CREAM}keybind reminder${RESET}  ${PINK}q${RESET} ${CREAM}close${RESET}  ${ORANGE}arrows/pgup${RESET} ${CREAM}scroll${RESET}"

render_content

if [[ "${SPO_RENDER_ONLY:-}" == 1 ]]; then
  cat "${content}"
  exit 0
fi

if command -v less >/dev/null 2>&1; then
  while true; do
    rm -f "${restart_flag}"
    render_content || true
    less -R -Ps"${status}" -Pm"${status}" -PM"${status}" +1g "${content}" &
    echo $! > "${less_pid_file}"
    wait "$(cat "${less_pid_file}")" || true
    rm -f "${less_pid_file}"
    if [[ -f "${restart_flag}" ]]; then
      continue
    fi
    break
  done
else
  printf "\033[2J\033[H"
  cat "${content}"
  printf "\n%s\n" "${status}"
  while IFS= read -rsn1 k; do
    case "${k}" in
      q|Q) exit 0 ;;
      x|X)
        state="$(tip_state)"
        mkdir -p "$(dirname "${TIP_FILE}")"
        if [[ "${state}" == off ]]; then
          printf "on\n" > "${TIP_FILE}"
        else
          printf "off\n" > "${TIP_FILE}"
        fi
        render_content
        printf "\033[2J\033[H"
        cat "${content}"
        printf "\n%s\n" "${status}"
        ;;
      w|W)
        if command -v xdg-open >/dev/null 2>&1; then
          setsid xdg-open "${SITE_URL}" </dev/null >/dev/null 2>&1 || true
        fi
        ;;
    esac
  done
fi
'
