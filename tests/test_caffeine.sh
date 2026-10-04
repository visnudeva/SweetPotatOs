#!/usr/bin/env bash
# Caffeine must not hold a systemd inhibitor. A lock kept across lid
# sleep leaves some laptops unable to wake.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/caffeine.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "${SCRIPT}" ]] || fail "missing ${SCRIPT}"
if grep -Eq '^[[:space:]]*systemd-inhibit[[:space:]]' "${SCRIPT}"; then
  fail "caffeine.sh takes a systemd-inhibit lock"
fi
grep -q 'caffeine on' "${SCRIPT}" || fail "missing caffeine on notice"
grep -q 'caffeine off' "${SCRIPT}" || fail "missing caffeine off notice"
grep -q 'Idle lock disabled' "${SCRIPT}" && fail "old caffeine notice is still there"
grep -q 'after-resume' "${SCRIPT}" && fail "caffeine still changes wake behavior"
grep -q 'output \* enable' "${SCRIPT}" && fail "caffeine still forces outputs on after wake"
echo "caffeine checks passed"
