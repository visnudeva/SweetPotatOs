#!/usr/bin/bash
# One-shot fix for gpgme "No data" during spo-upgrade on early Second Harvest installs.
# Run: curl -L ... | sudo bash   OR   sudo ./scripts/spo-fix-repo.sh
set -euo pipefail

[[ "${EUID}" -eq 0 ]] || { echo "Run as root: sudo $0" >&2; exit 1; }

SPO_REPO_BASE="${SPO_REPO_BASE:-https://downloads.sourceforge.net/project/sweetpotatos/repo/x86_64}"

echo "[*] Removing XferCommand (breaks official repo GPG checks)…"
sed -i '/^XferCommand = /d' /etc/pacman.conf

echo "[*] Fixing sweetpotatos repo config…"
install -Dm644 /dev/stdin /etc/pacman.d/sweetpotatos.conf <<'EOF'
[sweetpotatos]
SigLevel = Never
Server = https://downloads.sourceforge.net/project/sweetpotatos/repo/x86_64
EOF

echo "[*] Clearing corrupt pacman sync databases…"
for f in /var/lib/pacman/sync/*.db; do
  [[ -f "${f}" ]] || continue
  if ! file "${f}" | grep -q 'gzip compressed data'; then
    echo "    removing corrupt ${f} ($(file -b "${f}"))"
    rm -f "${f}" "${f}.sig" "${f}.part"
  fi
done
rm -f /var/lib/pacman/sync/sweetpotatos.db*

echo "[*] Syncing official Arch repos (overlay repo temporarily disabled)…"
mv /etc/pacman.d/sweetpotatos.conf /etc/pacman.d/sweetpotatos.conf.off
pacman -Sy
mv /etc/pacman.d/sweetpotatos.conf.off /etc/pacman.d/sweetpotatos.conf

echo "[*] Installing LocalSend fix (localsend-bin 1.18.0-2)…"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
db="${work}/sweetpotatos.db"
curl -Lf -o "${db}" "${SPO_REPO_BASE}/sweetpotatos.db"
fn="$(tar -xOzf "${db}" --wildcards 'localsend-bin-*/desc' | awk '/^%FILENAME%/{getline; print; exit}')"
[[ -n "${fn}" ]] || { echo "[!] localsend-bin not in overlay repo" >&2; exit 1; }
curl -Lf -o "${work}/${fn}" "${SPO_REPO_BASE}/${fn}"
pacman -U --needed --noconfirm "${work}/${fn}"

echo "[+] Done. LocalSend should work after logout. Run 'sudo spo-upgrade' again once updated."
