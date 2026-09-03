#!/usr/bin/env bash
# Remove the old SourceForge pacman overlay repo (ISO Files stay).
# Overlay packages now live on GitHub: ./github/upload-repo.sh
#
# Usage:
#   SF_USER=your_sf_username ./sourceforge/remove-repo.sh
#
# Needs working SourceForge shell SSH (Account Services → SSH keys).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SF_USER="${SF_USER:-visnudeva}"
SF_PROJECT="${SF_PROJECT:-sweetpotatos}"
EMPTY="${ROOT}/sourceforge/empty-repo-stage"

if [[ -z "${SF_USER}" ]]; then
  echo "Set your SourceForge username:"
  echo "  SF_USER=yourname $0"
  exit 1
fi

rm -rf "${EMPTY}"
mkdir -p "${EMPTY}"

FRS="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/"
FRS_ARCH="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/x86_64/"

echo "[*] Emptying ${FRS}"
rsync -avP --delete -e ssh "${EMPTY}/" "${FRS}"

echo "[*] Emptying ${FRS_ARCH} (legacy path)"
rsync -avP --delete -e ssh "${EMPTY}/" "${FRS_ARCH}" || true

cat <<EOF

[+] SourceForge pacman repo tree cleared.

Keep ISO release folders under Files; overlay upgrades use:
  https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo/
EOF
