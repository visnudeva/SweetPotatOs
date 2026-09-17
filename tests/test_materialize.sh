#!/usr/bin/env bash
# Unit tests for sweetpotatos-materialize seed-only + overlay behaviour.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAT="${ROOT}/packaging/sweetpotatos/sweetpotatos-materialize"
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
export XDG_CONFIG_HOME="${DEST}"
export XDG_STATE_HOME="${TMP}/state"
export HOME="${TMP}/home"

mkdir -p "${BASE}/swirl/config.d" "${BASE}/swirl/scripts" "${BASE}/kanshi"
echo "SHIPPED_CONFIG" >"${BASE}/swirl/config"
echo "SEED_USER_V1" >"${BASE}/swirl/config.d/user"
echo "AUTOTILE" >"${BASE}/swirl/scripts/autotile.lua"
echo "KANSHI_V1" >"${BASE}/kanshi/config"

# First materialize: everything appears.
bash "${MAT}" >/dev/null
assert_file "${DEST}/swirl/config" "materialize creates swirl/config"
assert_eq "SHIPPED_CONFIG" "$(cat "${DEST}/swirl/config")" "config content from base"
assert_eq "SEED_USER_V1" "$(cat "${DEST}/swirl/config.d/user")" "user seed created"
assert_eq "KANSHI_V1" "$(cat "${DEST}/kanshi/config")" "kanshi seed created"

# User edits durable files.
echo "USER_BINDS" >"${DEST}/swirl/config.d/user"
echo "KANSHI_CUSTOM" >"${DEST}/kanshi/config"
echo "SHIPPED_CONFIG_V2" >"${BASE}/swirl/config"
echo "SEED_USER_V2" >"${BASE}/swirl/config.d/user"
echo "KANSHI_V2" >"${BASE}/kanshi/config"
echo "AUTOTILE_V2" >"${BASE}/swirl/scripts/autotile.lua"

# Second materialize: clobber shipped, keep seeds.
bash "${MAT}" >/dev/null
assert_eq "SHIPPED_CONFIG_V2" "$(cat "${DEST}/swirl/config")" "shipped config upgraded"
assert_eq "AUTOTILE_V2" "$(cat "${DEST}/swirl/scripts/autotile.lua")" "scripts upgraded"
assert_eq "USER_BINDS" "$(cat "${DEST}/swirl/config.d/user")" "user override preserved"
assert_eq "KANSHI_CUSTOM" "$(cat "${DEST}/kanshi/config")" "kanshi seed preserved"

# Overlay wins over base for a shipped path.
mkdir -p "${DEST}/sweetpotatos/user_edits/swirl"
echo "OVERLAY_CONFIG" >"${DEST}/sweetpotatos/user_edits/swirl/config"
bash "${MAT}" >/dev/null
assert_eq "OVERLAY_CONFIG" "$(cat "${DEST}/swirl/config")" "user_edits overlay wins"

echo
echo "materialize: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
