#!/usr/bin/env bash
# Login reminder can be turned off, and the cheatsheet shows that state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SP="${SWEETPOTATO_DIR:-$(cd "${ROOT}/../SweetPotato" && pwd)}"
TIPS="${SP}/swirl/scripts/tips.sh"
CHEAT="${SP}/swirl/scripts/cheatsheet.sh"
SHEET="${SP}/swirl/cheatsheet.txt"

fail() { echo "FAIL: $*" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/home/.config/sweetpotatos" "${tmp}/home/.config/swirl" "${tmp}/run" "${tmp}/bin"
cp "${SHEET}" "${tmp}/home/.config/swirl/cheatsheet.txt"
cat >"${tmp}/bin/notify-send" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"${NOTIFY_LOG}"
EOF
chmod 755 "${tmp}/bin/notify-send"
cat >"${tmp}/bin/foot" <<'EOF'
#!/bin/bash
while [[ $# -gt 0 ]]; do
  if [[ "$1" == bash && "${2:-}" == -c ]]; then
    shift 2
    exec bash -c "$1"
  fi
  shift
done
echo "foot wrapper found no bash -c" >&2
exit 1
EOF
chmod 755 "${tmp}/bin/foot"

export HOME="${tmp}/home"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_RUNTIME_DIR="${tmp}/run"
export NOTIFY_LOG="${tmp}/notified"
export PATH="${tmp}/bin:${PATH}"
export TERM_BIN="${tmp}/bin/foot"
export SPO_RENDER_ONLY=1

run_tips() {
  timeout 2 bash "${TIPS}"
}

printf 'off\n' >"${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
rm -f "${NOTIFY_LOG}"
run_tips || fail "off tip should exit 0"
[[ ! -s "${NOTIFY_LOG}" ]] || fail "off tip still notified"

rm -f "${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
rm -f "${NOTIFY_LOG}"
set +e
timeout 1 bash "${TIPS}"
rc=$?
set -e
[[ "${rc}" -eq 124 ]] || fail "default tip should wait to notify (rc=${rc})"
[[ ! -s "${NOTIFY_LOG}" ]] || fail "default tip notified before the delay"

printf 'on\n' >"${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
set +e
timeout 1 bash "${TIPS}"
rc=$?
set -e
[[ "${rc}" -eq 124 ]] || fail "on tip should wait to notify (rc=${rc})"

: >"${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"
rm -f "${NOTIFY_LOG}"
run_tips || fail "session marker should skip the tip"
[[ ! -s "${NOTIFY_LOG}" ]] || fail "session marker still notified"
rm -f "${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"

render() {
  local out
  out="$(bash "${CHEAT}" | sed $'s/\033\\[[0-9;]*m//g')"
  printf '%s' "${out}"
}

printf 'off\n' >"${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
off="$(render)"
grep -q 'Keybind reminder       off' <<<"${off}" || fail "sheet did not show reminder off"
grep -q 'Press x to show it at login again' <<<"${off}" || fail "sheet missing turn-on hint"
grep -q 'Mod+?' <<<"${off}" || fail "sheet lost the Mod+? line"

rm -f "${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
on="$(render)"
grep -q 'Keybind reminder       on' <<<"${on}" || fail "sheet did not show reminder on"
grep -q 'Press x to hide the keybind reminder' <<<"${on}" || fail "sheet missing turn-off hint"

echo "login tip ok"
