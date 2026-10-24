#!/usr/bin/env bash
# Session wrapper keeps logout teardown off the login VT.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert() { bash -c "$1" || { echo "FAIL: $2" >&2; exit 1; }; echo "[OK] $2"; }

WRAP="${ROOT}/packaging/sweetpotatos/files/usr/local/bin/swirl"
SKEL="${ROOT}/profile/airootfs/etc/skel/.local/bin/swirl"
LY="${ROOT}/profile/airootfs/etc/ly/config.ini"

assert "[[ -x '${WRAP}' ]]" "system swirl wrapper is executable"
assert "grep -q 'ly-session.log' '${WRAP}'" "wrapper logs to ly-session.log"
assert "grep -q '2>&1' '${WRAP}'" "wrapper redirects stderr with stdout"
assert "! grep -q '/usr/local/bin/swirl' '${WRAP}' || ! grep -E 'for bin in.* /usr/local/bin/swirl' '${WRAP}'" \
  "wrapper does not recurse into itself"
# Prefer the quiet system wrapper from ~/.local/bin.
assert "grep -q '/usr/local/bin/swirl' '${SKEL}'" "skel swirl prefers the system wrapper"
assert "grep -q '/usr/local/bin' '${LY}'" "Ly PATH finds /usr/local/bin before /usr/bin"

echo "logout quiet checks passed"
