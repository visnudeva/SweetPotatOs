#!/usr/bin/env bash
# Sanity checks for sweetpotatos-update package candidate list + helpers.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPD="${ROOT}/packaging/sweetpotatos/sweetpotatos-update"
PASS=0
FAIL=0

assert() {
  local cond="$1" label="$2"
  if eval "${cond}"; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}"
    FAIL=$((FAIL + 1))
  fi
}

assert "[[ -x '${UPD}' || -f '${UPD}' ]]" "sweetpotatos-update exists"
assert "grep -q '^REPO_NAME=sweetpotatos$' '${UPD}'" "uses [sweetpotatos] repo"
assert "grep -q 'sweetpotatos$' '${UPD}'" "upgrades sweetpotatos package"
assert "grep -q 'swirl$' '${UPD}'" "upgrades swirl package"
assert "grep -q 'sweetpotatos-materialize' '${UPD}'" "runs materialize after upgrade"
assert "grep -q 'pacman -Syu' '${UPD}'" "reminds Arch lane is separate"
assert "! grep -q 'spo-upgrade' '${UPD}'" "no spo-upgrade"
assert "grep -q 'swaylock-effects' '${UPD}'" "upgrades swaylock-effects package"
assert "grep -q 'Removing swaylock' '${UPD}'" "removes stock swaylock before effects"
assert "grep -q '^swaylock-effects$' '${ROOT}/profile/packages.x86_64'" "ISO lists swaylock-effects"
assert "grep -q '^clock$' '${ROOT}/profile/airootfs/etc/skel/.config/swaylock/config'" \
  "skel swaylock config enables clock"
assert "grep -q '^indicator$' '${ROOT}/profile/airootfs/etc/skel/.config/swaylock/config'" \
  "skel swaylock config enables effects indicator"
assert "grep -q 'set \\\$lockcmd swaylock' \
  '${ROOT}/profile/airootfs/etc/skel/.config/swirl/config'" \
  "skel uses explicit swaylock config path"
assert "grep -q 'getent passwd' '${UPD}'" "materialize uses getent for user home"
assert "grep -q 'Pictures/Wallpapers' '${ROOT}/packaging/sweetpotatos/sweetpotatos-materialize'" \
  "materialize syncs wallpapers into Pictures/Wallpapers"
assert "grep -q 'usr/share/sweetpotato/backgrounds' '${ROOT}/packaging/sweetpotatos/PKGBUILD'" \
  "sweetpotatos package ships system wallpapers"
assert "[[ -f '${ROOT}/profile/airootfs/etc/skel/.config/swirl/config.d/user' ]]" \
  "skel ships config.d/user"
assert "grep -q 'include ~/.config/swirl/config.d/user' \
  '${ROOT}/profile/airootfs/etc/skel/.config/swirl/config'" \
  "skel config includes user override last"

echo
echo "update/channel: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
