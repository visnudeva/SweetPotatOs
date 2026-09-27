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
assert "grep -q -- '--testing' '${UPD}'" "supports --testing"
assert "grep -q -- '--stable' '${UPD}'" "supports --stable"
assert "grep -q 'pacman-repo-testing' '${UPD}'" "knows the testing release tag"
assert "grep -q 'releases/download/pacman-repo$' '${ROOT}/packaging/sweetpotatos/sweetpotatos.conf'" \
  "shipped conf defaults to the live channel"
assert "grep -q 'pacman-repo-testing' '${ROOT}/scripts/publish-repo.sh'" \
  "publish script can target the testing release"
assert "grep -q -- '--prerelease' '${ROOT}/scripts/publish-repo.sh'" \
  "testing release is marked prerelease"
assert "grep -q 'TAG=pacman-repo-testing' '${ROOT}/scripts/publish-repo.sh'" \
  "testing publish does not follow a leftover live TAG"
assert "grep -q 'sweetpotatos$' '${UPD}'" "upgrades sweetpotatos package"
assert "grep -q 'swirl$' '${UPD}'" "upgrades swirl package"
assert "grep -q 'sweetpotatos-materialize' '${UPD}'" "runs materialize after upgrade"
assert "grep -q 'pacman -Syu' '${UPD}'" "reminds Arch lane is separate"
assert "grep -q 'swaymsg reload' '${UPD}'" "reloads Swirl after materialize"
assert "grep -q 'Open Mod+?' '${UPD}'" "tells users Mod+? is enough after update"
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

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
cp "${ROOT}/packaging/sweetpotatos/sweetpotatos.conf" "${tmp}/sweetpotatos.conf"
run_apply() {
  SWEETPOTATOS_UPDATE_APPLY_ONLY=1 \
    SWEETPOTATOS_UPDATE_CONF="${tmp}/sweetpotatos.conf" \
    SWEETPOTATOS_UPDATE_CHANNEL_FILE="${tmp}/channel" \
    bash "${UPD}" "$@"
}
assert "run_apply --testing >/dev/null" "switches a copy of the conf to testing"
assert "grep -q 'download/pacman-repo-testing$' '${tmp}/sweetpotatos.conf'" \
  "testing Server URL is pacman-repo-testing"
assert "[[ \$(tr -d '[:space:]' < '${tmp}/channel') == testing ]]" "channel file records testing"
assert "run_apply >/dev/null" "plain update stays on the testing channel"
assert "grep -q 'download/pacman-repo-testing$' '${tmp}/sweetpotatos.conf'" \
  "staying on testing does not fall back to live"
assert "run_apply --stable >/dev/null" "switches back to stable"
assert "grep -q 'download/pacman-repo$' '${tmp}/sweetpotatos.conf'" \
  "stable Server URL is pacman-repo"
assert "[[ \$(tr -d '[:space:]' < '${tmp}/channel') == stable ]]" "channel file records stable"
printf '%s\n' '[sweetpotatos]' 'SigLevel = Optional TrustAll' \
  'Server = file:///tmp/SweetPotatOs/repo' >"${tmp}/sweetpotatos.conf"
assert "! run_apply --testing >/dev/null 2>&1" "refuses to rewrite a file:// Server"

echo
echo "update/channel: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
