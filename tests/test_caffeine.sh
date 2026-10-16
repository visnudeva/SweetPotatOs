#!/usr/bin/env bash
# Caffeine must not hold a systemd inhibitor. A lock kept across lid
# sleep leaves some laptops unable to wake. after-resume may turn the
# panel back on; it must not use "output * enable".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/caffeine.sh"
SUSPEND="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/suspend.sh"
CFG="${ROOT}/profile/airootfs/etc/skel/.config/swirl/config"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "${SCRIPT}" ]] || fail "missing ${SCRIPT}"
[[ -x "${SUSPEND}" ]] || fail "missing executable suspend.sh"
if grep -Eq '^[[:space:]]*systemd-inhibit[[:space:]]' "${SCRIPT}"; then
  fail "caffeine.sh takes a systemd-inhibit lock"
fi
grep -q 'caffeine on' "${SCRIPT}" || fail "missing caffeine on notice"
grep -q 'caffeine off' "${SCRIPT}" || fail "missing caffeine off notice"
grep -q 'Idle lock disabled' "${SCRIPT}" && fail "old caffeine notice is still there"
grep -q 'output \* enable' "${SCRIPT}" && fail "caffeine still forces outputs on after wake with enable"
grep -q "after-resume 'swaymsg \"output \* power on\"'" "${SCRIPT}" \
  || fail "caffeine must power the panel back on after resume"
grep -q "after-resume 'swaymsg \"output \* power on\"'" "${CFG}" \
  || fail "session swayidle must power the panel back on after resume"
grep -q 'suspend\.sh' \
  "${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/power-menu.sh" \
  || fail "power menu must sleep via suspend.sh"
grep -q 'systemctl suspend' "${SUSPEND}" || fail "suspend.sh must call systemctl suspend"
echo "caffeine checks passed"
