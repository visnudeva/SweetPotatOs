#!/usr/bin/env bash
# Sweet potato hue sliders recolor that preset only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="${ROOT}/../SweetPotato/swirl/scripts/theme.sh"
SKEL="${ROOT}/profile/airootfs/etc/skel/.config/swirl/scripts/theme.sh"
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

assert_ne() {
  local other="$1" got="$2" label="$3"
  if [[ "${other}" != "${got}" ]]; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}: still '${got}'"
    FAIL=$((FAIL + 1))
  fi
}

field() {
  local file="$1" key="$2"
  sed -n "s/^${key}=//p" "${file}" | tail -n 1
}

[[ -x "${THEME}" ]]
grep -q 'hue-apply' "${SKEL}"

presets="$("${THEME}" presets)"
printf '%s\n' "${presets}" | grep -q $'ube\tUbe\tdark'
printf '%s\n' "${presets}" | grep -q $'cyberpunk\tCyberpunk\tdark'
printf '%s\n' "${presets}" | grep -q $'dragon-fruit\tDragon fruit\tlight'
echo "[PASS] presets list the named themes"
PASS=$((PASS + 1))

default_accent="$("${THEME}" hue-hex a73b50 348.33)"
assert_eq "a73b50" "${default_accent}" "default pink hue round-trips"
shifted="$("${THEME}" hue-hex a73b50 120)"
assert_ne "a73b50" "${shifted}" "pink hue 120 changes the color"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
export SPO_CONFIG_ROOT="${TMP}"

"${THEME}" --quiet set ube
assert_eq "9346c8" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "ube keeps its accent"
assert_eq "ube" "$(field "${TMP}/sweetpotatos/theme" id)" "ube id"

"${THEME}" --quiet hue-apply dark 120 200
assert_eq "sweet-potato" "$(field "${TMP}/sweetpotatos/theme" id)" "slider selects sweet potato"
assert_eq "1d1f21" "$(field "${TMP}/sweetpotatos/active.sh" SPO_SURFACE)" "dark surface stays charcoal"
assert_ne "a73b50" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "pink slider recolors the accent"
assert_ne "f79b29" "$(field "${TMP}/sweetpotatos/active.sh" SPO_HIGHLIGHT)" "orange slider recolors the highlight"

"${THEME}" --quiet set ube
assert_eq "9346c8" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "ube is unchanged after a custom sweet potato"

"${THEME}" --quiet set sweet-potato
assert_ne "a73b50" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "returning to sweet potato keeps the saved hues"

"${THEME}" --quiet hue-apply light 120 200
assert_eq "sweet-potato-light" "$(field "${TMP}/sweetpotatos/theme" id)" "light toggle selects the light preset"
assert_eq "f4f1ec" "$(field "${TMP}/sweetpotatos/active.sh" SPO_SURFACE)" "light surface is off-white"
assert_eq "241e20" "$(field "${TMP}/sweetpotatos/active.sh" SPO_TEXT)" "light text is the light-theme ink"
assert_ne "a73b50" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "light preset still takes the pink hue"

ube_hues="$(python3 - << 'PY'
import colorsys
def hue(h):
    r, g, b = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    H, _l, _s = colorsys.rgb_to_hls(r, g, b)
    return f"{H * 360:.2f}"
print(hue("9346c8"), hue("c9a0f5"))
PY
)"
# shellcheck disable=SC2086
"${THEME}" --quiet hue-apply ube ${ube_hues}
assert_eq "9346c8" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "ube's own hues stay ube"
"${THEME}" --quiet hue-apply ube 10 200
assert_ne "9346c8" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "ube sliders recolor ube"
"${THEME}" --quiet set lime
assert_eq "2bd45a" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "lime stays lime beside a custom ube"

"${THEME}" --quiet hue-apply dark 348.33 33.20
assert_eq "a73b50" "$(field "${TMP}/sweetpotatos/active.sh" SPO_ACCENT)" "reset pink is the original"
assert_eq "f79b29" "$(field "${TMP}/sweetpotatos/active.sh" SPO_HIGHLIGHT)" "reset orange is the original"

mkdir -p "${TMP}/fastfetch"
printf '%s\n' '{
  "logo": { "type": "chafa", "source": "'"${TMP}"'/fastfetch/SPLogo.png", "width": 28, "height": 14 },
  "display": { "color": { "keys": "#a73b50", "title": "#f79b29" } }
}' > "${TMP}/fastfetch/config.jsonc"
printf 'potato\n' > "${TMP}/fastfetch/SPLogo.png"

logo_source() {
  sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${TMP}/fastfetch/config.jsonc"
}

"${THEME}" --quiet set sweet-potato
assert_eq "${TMP}/fastfetch/KanjiLogo.png" "$(logo_source)" "sweet potato uses the kanji logo"
[[ -s "${TMP}/fastfetch/KanjiLogo.png" ]]
echo "[PASS] sweet potato kanji logo was drawn"
PASS=$((PASS + 1))

"${THEME}" --quiet set lime
assert_eq "${TMP}/fastfetch/SPLogo.png" "$(logo_source)" "lime puts the potato logo back"

"${THEME}" --quiet set ube
assert_eq "${TMP}/fastfetch/KanjiLogo.png" "$(logo_source)" "ube uses the kanji logo"

"${THEME}" --quiet set sweet-potato-light
assert_eq "${TMP}/fastfetch/SPLogo.png" "$(logo_source)" "light sweet potato keeps the potato logo"

echo "${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
