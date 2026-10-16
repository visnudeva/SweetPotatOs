#!/usr/bin/env bash
# Smart Brightness detection (ported from fullscreen-maxbright).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/smart-brightness-lib.py"
DAEMON="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/smart-brightness.sh"
CFG="${ROOT}/profile/airootfs/etc/skel/.config/swirl/config"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "${LIB}" ]] || fail "missing ${LIB}"
[[ -x "${DAEMON}" ]] || fail "missing executable ${DAEMON}"

check() {
  python3 "${LIB}" check "$@"
}

[[ "$(check 1 mpv movie.mkv)" == 1 ]] || fail "mpv fullscreen should activate"
[[ "$(check 1 firefox 'YouTube - cats')" == 1 ]] || fail "firefox YouTube should activate"
[[ "$(check 1 Brave-browser Netflix)" == 1 ]] || fail "brave Netflix should activate"
[[ "$(check 1 org.gnome.Nautilus Home)" == 0 ]] || fail "nautilus fullscreen should not activate"
[[ "$(check 1 Code extension.js)" == 0 ]] || fail "code fullscreen should not activate"
[[ "$(check 0 mpv movie.mkv)" == 0 ]] || fail "windowed mpv should not activate"

tree_fs="$(python3 "${LIB}" check-tree <<'JSON'
{"focused":false,"nodes":[{"type":"workspace","focused":false,"floating_nodes":[],"nodes":[{"type":"con","focused":true,"fullscreen_mode":1,"app_id":"mpv","name":"film.mkv","nodes":[],"floating_nodes":[]}]}],"floating_nodes":[]}
JSON
)"
tree_tile="$(python3 "${LIB}" check-tree <<'JSON'
{"focused":false,"nodes":[{"type":"workspace","focused":false,"floating_nodes":[],"nodes":[{"type":"con","focused":true,"fullscreen_mode":0,"app_id":"mpv","name":"film.mkv","nodes":[],"floating_nodes":[]}]}],"floating_nodes":[]}
JSON
)"
[[ "${tree_fs}" == 1 ]] || fail "fullscreen_mode=1 should activate"
[[ "${tree_tile}" == 0 ]] || fail "fullscreen_mode=0 (strip maximize) must not activate"

grep -q 'smart-brightness.sh daemon' "${CFG}" || fail "config must start the daemon"
grep -q 'smart-brightness.sh toggle' "${CFG}" || fail "config must bind the toggle"

echo "smart-brightness checks passed"
