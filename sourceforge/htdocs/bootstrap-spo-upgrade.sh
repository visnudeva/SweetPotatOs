#!/usr/bin/bash
# Bootstrap SweetPotatOs overlay upgrades onto GitHub (Second Harvest recovery).
# Safe to re-run. Needs root.
#
#   curl -fsSL https://sweetpotatos.sourceforge.io/bootstrap-spo-upgrade.sh | sudo bash
#
set -euo pipefail

[[ "${EUID}" -eq 0 ]] || { echo "run as root: curl -fsSL https://sweetpotatos.sourceforge.io/bootstrap-spo-upgrade.sh | sudo bash" >&2; exit 1; }

GH_BASE='https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo'
REPO_CONF=/etc/pacman.d/sweetpotatos.conf
PKG_URL="${GH_BASE}/sweetpotatos-2026.09.1-7-any.pkg.tar.zst"

echo "[bootstrap] Pointing overlay repo at GitHub…"
install -Dm644 /dev/stdin "${REPO_CONF}" <<EOF
[sweetpotatos]
SigLevel = Never
Server = ${GH_BASE}
EOF

# Dead mirror aborts the whole pacman transaction if contacted.
if [[ -f /etc/pacman.conf ]]; then
  sed -i '/sf-mirror.net/d' /etc/pacman.conf
fi
sed -i '/sf-mirror.net/d' "${REPO_CONF}" 2>/dev/null || true

if [[ -f /etc/pacman.conf ]] && ! grep -qF 'Include = /etc/pacman.d/sweetpotatos.conf' /etc/pacman.conf; then
  printf '\nInclude = /etc/pacman.d/sweetpotatos.conf\n' >> /etc/pacman.conf
fi

echo "[bootstrap] Downloading sweetpotatos package…"
tmp="$(mktemp /tmp/sweetpotatos.XXXXXX.pkg.tar.zst)"
trap 'rm -f "${tmp}"' EXIT
curl -fL --connect-timeout 30 --retry 3 -o "${tmp}" "${PKG_URL}"

echo "[bootstrap] Installing sweetpotatos (new spo-upgrade)…"
pacman -U --noconfirm --needed "${tmp}"

echo "[bootstrap] Running spo-upgrade…"
exec /usr/local/bin/spo-upgrade
