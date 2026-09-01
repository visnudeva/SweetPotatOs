#!/usr/bin/env bash
# Publish the local SweetPotatOs pacman repo to SourceForge (for spo-upgrade on installed systems).
#
# Usage:
#   SF_USER=your_sf_username ./sourceforge/upload-repo.sh
#
# Layout on SourceForge (matches /etc/pacman.d/sweetpotatos.conf):
#   project/sweetpotatos/repo/sweetpotatos.db.tar.gz
#   project/sweetpotatos/repo/*.pkg.tar.*
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${ROOT}/repo"
STAGE="${ROOT}/sourceforge/repo-stage"
SF_USER="${SF_USER:-}"
SF_PROJECT="${SF_PROJECT:-sweetpotatos}"
ARCH="${ARCH:-x86_64}"

if [[ -z "${SF_USER}" ]]; then
  echo "Set your SourceForge username:"
  echo "  SF_USER=yourname $0"
  exit 1
fi

if ! ls "${REPO}"/*.pkg.tar.* >/dev/null 2>&1; then
  echo "No packages in ${REPO}/ — run: sudo ./build.sh --build-packages"
  exit 1
fi

echo "[*] Refreshing repo database…"
rm -f "${REPO}/sweetpotatos.db.tar.gz" "${REPO}/sweetpotatos.db" \
      "${REPO}/sweetpotatos.files.tar.gz" "${REPO}/sweetpotatos.files"
repo-add "${REPO}/sweetpotatos.db.tar.gz" "${REPO}"/*.pkg.tar.*

mkdir -p "${STAGE}"
cp -a "${REPO}"/*.pkg.tar.* "${STAGE}/"
cp -a "${REPO}/sweetpotatos.db.tar.gz" "${STAGE}/"

FRS="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/"
FRS_ARCH="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/${ARCH}/"

echo "[*] Uploading pacman repo to ${FRS}"
rsync -avP --delete -e ssh "${STAGE}/" "${FRS}"

echo "[*] Uploading pacman repo to ${FRS_ARCH} (early Second Harvest used repo/\$arch/)"
rsync -avP --delete -e ssh "${STAGE}/" "${FRS_ARCH}"

cat <<EOF

[+] Pacman repo uploaded.

Installed systems can upgrade with:
  sudo spo-upgrade

Repo URL (already in sweetpotatos package):
  https://downloads.sourceforge.net/project/${SF_PROJECT}/repo/
EOF
