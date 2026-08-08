#!/usr/bin/env bash
# Upload SweetPotatOs ISO (+ checksum) and project web to SourceForge via rsync.
# Usage:
#   SF_USER=your_sf_username ./sourceforge/upload.sh
# Optional:
#   SF_RELEASE=2026.08.08 ./sourceforge/upload.sh   # FRS folder name
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SF_USER="${SF_USER:-}"
SF_PROJECT="${SF_PROJECT:-sweetpotatos}"
SF_RELEASE="${SF_RELEASE:-2026.08.08}"
ISO_NAME="SweetPotatOs-${SF_RELEASE}-x86_64.iso"
ISO_SRC="${ROOT}/out/${ISO_NAME}"
FILES_DIR="${ROOT}/sourceforge/files"
HTDOCS="${ROOT}/sourceforge/htdocs"

if [[ -z "${SF_USER}" ]]; then
  echo "Set your SourceForge username:"
  echo "  SF_USER=yourname $0"
  exit 1
fi

if [[ ! -f "${ISO_SRC}" ]]; then
  echo "ISO not found: ${ISO_SRC}"
  echo "Build first, or set SF_RELEASE to match out/SweetPotatOs-*-x86_64.iso"
  exit 1
fi

mkdir -p "${FILES_DIR}"
ln -sfn "${ISO_SRC}" "${FILES_DIR}/${ISO_NAME}"

if [[ ! -f "${FILES_DIR}/${ISO_NAME}.sha256" ]]; then
  echo "[*] Computing SHA256 (a few minutes)…"
  (cd "${FILES_DIR}" && sha256sum "${ISO_NAME}" | tee "${ISO_NAME}.sha256")
fi

FRS="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${SF_RELEASE}/"
WEB="${SF_USER}@web.sourceforge.net:/home/project-web/${SF_PROJECT}/htdocs/"

echo "[*] Uploading release files to ${FRS}"
echo "    (enter your SourceForge password or use an SSH key)"
rsync -avP -e ssh \
  "${FILES_DIR}/${ISO_NAME}" \
  "${FILES_DIR}/${ISO_NAME}.sha256" \
  "${FRS}"

echo "[*] Uploading project web to ${WEB}"
rsync -avP -e ssh "${HTDOCS}/" "${WEB}"

cat <<EOF

[+] Done.

Download page:
  https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_RELEASE}/

Direct ISO (after mirrors sync, can take a bit):
  https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_RELEASE}/${ISO_NAME}/download

Project web:
  https://${SF_PROJECT}.sourceforge.io/
  (or https://sourceforge.net/projects/${SF_PROJECT}/)

Still set in the SourceForge web UI:
  Admin → Settings → Icon  (use assets/SweetPotatOs.png or SPLogo.png)
  Admin → Settings → Summary / Categories
EOF
