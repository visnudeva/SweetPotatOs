#!/usr/bin/env bash
# Overview packaging contracts: one Mod+Tab bind, equal-height stripes,
# click exits before focus, no retired smooth-jump / Shift+Tab paths.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKEL_CFG="${ROOT}/profile/airootfs/etc/skel/.config/swirl/config"
LIVE_CFG="${ROOT}/profile/airootfs/home/liveuser/.config/swirl/config"
SESSION_CFG="${ROOT}/packaging/swirl/session/config"
CHEAT="${ROOT}/profile/airootfs/etc/skel/.config/swirl/cheatsheet.txt"
PKGBUILD="${ROOT}/packaging/swirl/PKGBUILD"
CLICK="${ROOT}/packaging/swirl/overview-click-zoom.patch"
COVER="${ROOT}/packaging/swirl/overview-coverflow-stripes.patch"
FIT="${ROOT}/packaging/swirl/overview-fit-strips.patch"
ESC="${ROOT}/packaging/swirl/overview-escape-exit.patch"
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

assert "[[ -f '${SKEL_CFG}' ]]" "skel swirl config exists"
assert "grep -q 'scale_workspaces toggle' '${SKEL_CFG}'" "skel Mod+Tab toggles overview"
assert "! grep -qE 'Shift\\+Tab|scale_workspace overview' '${SKEL_CFG}'" \
  "skel has no Mod+Shift+Tab / scale_workspace overview"
assert "grep -q 'scale_workspaces toggle' '${LIVE_CFG}'" "liveuser Mod+Tab toggles overview"
assert "! grep -qE 'Shift\\+Tab|scale_workspace overview' '${LIVE_CFG}'" \
  "liveuser has no Mod+Shift+Tab / scale_workspace overview"
assert "grep -q 'scale_workspaces toggle' '${SESSION_CFG}'" "default session Mod+Tab toggles overview"
assert "! grep -qE 'Shift\\+Tab|scale_workspace overview' '${SESSION_CFG}'" \
  "default session has no Mod+Shift+Tab / scale_workspace overview"
assert "grep -qi 'Overview' '${CHEAT}'" "cheatsheet mentions overview"
assert "! grep -q 'Shift+Tab' '${CHEAT}'" "cheatsheet has no Shift+Tab"

assert "[[ -f '${FIT}' ]]" "overview-fit-strips patch present"
assert "[[ -f '${COVER}' ]]" "overview-coverflow-stripes patch present"
assert "[[ -f '${CLICK}' ]]" "overview-click-zoom patch present"
assert "! [[ -e '${ROOT}/packaging/swirl/overview-smooth-jump.patch' ]]" \
  "retired overview-smooth-jump patch is gone"
assert "grep -q 'overview-fit-strips.patch' '${PKGBUILD}'" "PKGBUILD applies fit-strips"
assert "grep -q 'overview-coverflow-stripes.patch' '${PKGBUILD}'" "PKGBUILD applies coverflow"
assert "grep -q 'overview-click-zoom.patch' '${PKGBUILD}'" "PKGBUILD applies click-zoom"
assert "! grep -q 'overview-smooth-jump' '${PKGBUILD}'" "PKGBUILD does not apply smooth-jump"

assert "grep -q 'equal-height horizontal stripes' '${COVER}'" \
  "coverflow patch uses equal-height stripes"
assert "grep -q 'No workspace numbers/names' '${COVER}'" \
  "coverflow patch hides workspace labels"
assert "grep -q 'workspace_name_decoration(child, false)' '${COVER}'" \
  "coverflow patch does not enable name decorations"
assert "! grep -q 'focus_weight' '${COVER}'" "coverflow patch has no focus_weight reflow"
assert "! grep -q 'layout_overview_workspaces_recompute_scale' '${COVER}'" \
  "coverflow patch does not reflow on seat focus"
assert "grep -q 'Exit overview first' '${CLICK}' || grep -q 'Exit overview before focus' '${CLICK}'" \
  "click-zoom exits overview before focus"
assert "grep -q 'OVERVIEW_ALL' '${FIT}'" "fit-strips shows every window stripe"
assert "grep -q 'XKB_KEY_Escape' '${ESC}'" "escape-exit patch handles Escape"
assert "grep -q 'round(sx + sw)' '${ROOT}/packaging/swirl/overview-border-clip.patch'" "border-clip uses non-overlapping round scale"

assert "grep -q 'animations' '${SKEL_CFG}'" "skel enables overview animation block"
assert "grep -q 'overview yes' '${SKEL_CFG}'" "skel sets overview animation curve"

echo
echo "overview: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
