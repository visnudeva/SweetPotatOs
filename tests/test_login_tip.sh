#!/usr/bin/env bash
# Login opens Settings once unless turned off (Settings → Open Settings at login).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SP="${SWEETPOTATO_DIR:-$(cd "${ROOT}/../SweetPotato" && pwd)}"
TIPS="${SP}/swirl/scripts/tips.sh"
CHEAT="${SP}/swirl/scripts/cheatsheet.sh"
SHEET="${SP}/swirl/cheatsheet.txt"

fail() { echo "FAIL: $*" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/home/.config/sweetpotatos" "${tmp}/home/.config/swirl/scripts" "${tmp}/run" "${tmp}/bin"
cp "${SHEET}" "${tmp}/home/.config/swirl/cheatsheet.txt"
# Minimal settings.py so tips can "launch" something under the test HOME.
printf 'print("settings-ok")\n' >"${tmp}/home/.config/swirl/scripts/settings.py"

cat >"${tmp}/bin/python3" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"${LAUNCH_LOG}"
exit 0
EOF
chmod 755 "${tmp}/bin/python3"

export HOME="${tmp}/home"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_RUNTIME_DIR="${tmp}/run"
export LAUNCH_LOG="${tmp}/launched"
export PATH="${tmp}/bin:${PATH}"
export SPO_RENDER_ONLY=1

run_tips() {
  timeout 2 bash "${TIPS}"
}

printf 'off\n' >"${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
rm -f "${LAUNCH_LOG}"
run_tips || fail "off tip should exit 0"
[[ ! -f "${LAUNCH_LOG}" ]] || fail "off tip still launched Settings"

rm -f "${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
rm -f "${LAUNCH_LOG}" "${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"
set +e
timeout 1 bash "${TIPS}"
rc=$?
set -e
[[ "${rc}" -eq 124 ]] || fail "default tip should wait before opening (rc=${rc})"
[[ ! -f "${LAUNCH_LOG}" ]] || fail "Settings launched before the delay"

printf 'on\n' >"${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
rm -f "${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"
set +e
timeout 1 bash "${TIPS}"
rc=$?
set -e
[[ "${rc}" -eq 124 ]] || fail "on tip should wait before opening (rc=${rc})"

: >"${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"
rm -f "${LAUNCH_LOG}"
run_tips || fail "session marker should skip opening Settings"
[[ ! -f "${LAUNCH_LOG}" ]] || fail "session marker still launched Settings"
rm -f "${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"

# After the delay, Settings should launch once.
rm -f "${LAUNCH_LOG}" "${XDG_RUNTIME_DIR}/sweetpotato-tips-shown"
rm -f "${XDG_CONFIG_HOME}/sweetpotatos/login-tip"
# Override sleep by running a copy with sleep 0 — or just wait past sleep 3.
set +e
timeout 5 bash "${TIPS}"
rc=$?
set -e
[[ "${rc}" -eq 0 ]] || fail "tips should exit 0 after launching (rc=${rc})"
[[ -s "${LAUNCH_LOG}" ]] || fail "Settings was not launched"
grep -q 'settings.py' "${LAUNCH_LOG}" || fail "launch log missing settings.py"

render() {
  local out
  out="$(bash "${CHEAT}" | sed $'s/\033\\[[0-9;]*m//g')"
  printf '%s' "${out}"
}

sheet="$(render)"
grep -q 'Mod+?' <<<"${sheet}" || fail "sheet lost the Mod+? line"
grep -q 'Mod+,' <<<"${sheet}" || fail "sheet lost Mod+, Settings"

echo "login tip ok"
