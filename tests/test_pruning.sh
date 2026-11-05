#!/usr/bin/env bash
# Unit tests for sweetpotatos-pruning.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRUNE="${ROOT}/packaging/sweetpotatos/sweetpotatos-pruning"
SPROUT="${ROOT}/packaging/sweetpotatos/sweetpotatos-sprout"
PASS=0
FAIL=0

assert_eq() {
  local want="$1" got="$2" label="$3"
  if [[ "${want}" == "${got}" ]]; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}: want='${want}' got='${got}'"
    FAIL=$((FAIL + 1))
  fi
}

assert_missing() {
  local f="$1" label="$2"
  if [[ ! -e "${f}" ]]; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}: still present ${f}"
    FAIL=$((FAIL + 1))
  fi
}

assert_file() {
  local f="$1" label="$2"
  if [[ -f "${f}" ]]; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}: missing ${f}"
    FAIL=$((FAIL + 1))
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

BASE="${TMP}/base"
DEST="${TMP}/config"
export SWEETPOTATO_CONFIG_BASE="${BASE}"
export SWEETPOTATO_BACKGROUNDS="${TMP}/no-walls"
export SWEETPOTATOS_SPROUT="${SPROUT}"
export XDG_CONFIG_HOME="${DEST}"
export XDG_STATE_HOME="${TMP}/state"
export HOME="${TMP}/home"
mkdir -p "${HOME}"

mkdir -p "${BASE}/swirl/config.d" "${BASE}/swirl/scripts" "${BASE}/kanshi" "${BASE}/foot"
echo "SHIPPED_CONFIG" >"${BASE}/swirl/config"
echo "SEED_USER" >"${BASE}/swirl/config.d/user"
echo "AUTOTILE" >"${BASE}/swirl/scripts/autotile.lua"
echo "KANSHI" >"${BASE}/kanshi/config"
echo "FOOT" >"${BASE}/foot/foot.ini"

bash "${SPROUT}" >/dev/null

# Mess things up: edit shipped files, add orphan junk, plant a bad overlay.
echo "BROKEN_CONFIG" >"${DEST}/swirl/config"
echo "MY_BINDS" >"${DEST}/swirl/config.d/user"
echo "MY_KANSHI" >"${DEST}/kanshi/config"
echo "ORPHAN" >"${DEST}/swirl/scripts/i-broke-it.sh"
mkdir -p "${DEST}/sweetpotatos/user_edits/swirl"
echo "OVERLAY_BROKEN" >"${DEST}/sweetpotatos/user_edits/swirl/config"
echo "THEME_STATE" >"${DEST}/sweetpotatos/theme"
echo "SHIPPED_CONFIG_V2" >"${BASE}/swirl/config"
echo "AUTOTILE_V2" >"${BASE}/swirl/scripts/autotile.lua"

bash "${PRUNE}" --yes >/dev/null

assert_eq "SHIPPED_CONFIG_V2" "$(cat "${DEST}/swirl/config")" "shipped config restored"
assert_eq "AUTOTILE_V2" "$(cat "${DEST}/swirl/scripts/autotile.lua")" "scripts restored"
assert_eq "MY_BINDS" "$(cat "${DEST}/swirl/config.d/user")" "personal user file kept"
assert_eq "MY_KANSHI" "$(cat "${DEST}/kanshi/config")" "kanshi layout kept"
assert_eq "THEME_STATE" "$(cat "${DEST}/sweetpotatos/theme")" "theme state kept"
assert_missing "${DEST}/swirl/scripts/i-broke-it.sh" "orphan junk removed"
assert_missing "${DEST}/sweetpotatos/user_edits" "user_edits cleared"

stamp_dir="$(find "${XDG_STATE_HOME}/sweetpotatos/pruning-backups" -mindepth 1 -maxdepth 1 -type d | head -1)"
assert_file "${stamp_dir}/user_edits/swirl/config" "backup has overlay copy"
assert_eq "OVERLAY_BROKEN" "$(cat "${stamp_dir}/user_edits/swirl/config")" "backup overlay content"
assert_file "${stamp_dir}/config/swirl/config" "backup has removed config"
assert_eq "BROKEN_CONFIG" "$(cat "${stamp_dir}/config/swirl/config")" "backup had the broken config"
assert_file "${stamp_dir}/config/swirl/scripts/i-broke-it.sh" "backup has orphan junk"

echo
echo "pruning: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
