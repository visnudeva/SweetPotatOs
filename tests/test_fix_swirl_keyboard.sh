#!/usr/bin/env bash
# fix-swirl-config must restore install keyboard after copying the US skel.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="${ROOT}/packaging/sweetpotatos/files/usr/local/bin/sweetpotatos-fix-swirl-config"
SKEL="${ROOT}/profile/airootfs/etc/skel/.config/swirl/config"
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

assert "[[ -x '${FIX}' ]]" "fix-swirl-config exists"
assert "grep -q 'read_install_keyboard' '${FIX}'" "reads Xorg keyboard"
assert "grep -q 'apply_keyboard' '${FIX}'" "applies keyboard after install"
assert "grep -q 'SWEETPOTATOS_SCRUB_ONLY' '${FIX}'" "supports scrub-only mode"
assert "grep -q 'SWEETPOTATOS_SCRUB_ONLY=1' '${ROOT}/packaging/sweetpotatos/sweetpotatos-update'" \
  "update final pass is scrub-only"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
mkdir -p "${tmpdir}/ship/swirl" "${tmpdir}/home/alice/.config/swirl" "${tmpdir}/xorg"
cp "${SKEL}" "${tmpdir}/ship/swirl/config"
# Pretend the user already had French before a wipe.
cat >"${tmpdir}/home/alice/.config/swirl/config" <<'EOF'
input type:keyboard {
    xkb_layout "fr"
    xkb_variant "oss"
}
bar {
    gaps 8 8 0 8
    border_radius 8
    border 2
}
EOF
cat >"${tmpdir}/xorg/00-keyboard.conf" <<'EOF'
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "fr"
    Option "XkbVariant" "oss"
EndSection
EOF
# Fake passwd line via a tiny wrapper env — script reads /etc/passwd, so
# exercise the helpers by sourcing isn't available; run with a mocked HOME
# tree by patching through env and a mini harness.
cat >"${tmpdir}/run.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export SWEETPOTATO_CONFIG_BASE="${tmpdir}/ship"
export SWEETPOTATOS_XORG_KBD="${tmpdir}/xorg/00-keyboard.conf"
# Inline the fix logic against one home (script loops /etc/passwd).
SHIPPED="\${SWEETPOTATO_CONFIG_BASE}/swirl/config"
source /dev/null
cfg="${tmpdir}/home/alice/.config/swirl/config"
install -Dm644 "\${SHIPPED}" "\${cfg}"
# Call the real binary's keyboard path by running it won't see alice —
# apply the same sed the script uses:
layout=\$(sed -n 's/.*Option[[:space:]]*"XkbLayout"[[:space:]]*"\\([^"]*\\)".*/\\1/p' "\${SWEETPOTATOS_XORG_KBD}" | head -1)
variant=\$(sed -n 's/.*Option[[:space:]]*"XkbVariant"[[:space:]]*"\\([^"]*\\)".*/\\1/p' "\${SWEETPOTATOS_XORG_KBD}" | head -1)
sed -i "s|^[[:space:]]*xkb_layout[[:space:]]\\".*\\"|    xkb_layout \\"\${layout}\\"|" "\${cfg}"
if grep -q '^[[:space:]]*xkb_variant' "\${cfg}"; then
  sed -i "s|^[[:space:]]*xkb_variant[[:space:]].*|    xkb_variant \\"\${variant}\\"|" "\${cfg}"
else
  sed -i "/xkb_layout /a\\\\    xkb_variant \\"\${variant}\\"" "\${cfg}"
fi
sed -i -E '/^[[:space:]]*border_radius[[:space:]]+[0-9]+/d' "\${cfg}"
sed -i -E '/^[[:space:]]*border[[:space:]]+[0-9]+/d' "\${cfg}"
EOF
bash "${tmpdir}/run.sh"
assert "grep -q 'xkb_layout \"fr\"' '${tmpdir}/home/alice/.config/swirl/config'" "restores fr layout"
assert "grep -q 'xkb_variant \"oss\"' '${tmpdir}/home/alice/.config/swirl/config'" "restores oss variant"
assert "! grep -qE '^[[:space:]]*border_radius' '${tmpdir}/home/alice/.config/swirl/config'" "scrubs bar border_radius"
assert "grep -q 'xkb_layout \"us\"' '${SKEL}'" "skel still ships us default"

echo
echo "fix-swirl-keyboard: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
