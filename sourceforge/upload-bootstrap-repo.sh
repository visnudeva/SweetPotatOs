#!/usr/bin/env bash
# Publish a SourceForge bootstrap pacman mirror for Second Harvest systems that
# still have Server = …/project/sweetpotatos/repo[/x86_64] in pacman.
# GitHub Release pacman-repo remains the canonical overlay; this mirror unblocks
# the first upgrade after the SF tree was cleared.
#
# Usage:
#   ./sourceforge/upload-bootstrap-repo.sh
#   SF_USER=visnudeva ./sourceforge/upload-bootstrap-repo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${ROOT}/repo"
STAGE="${ROOT}/sourceforge/bootstrap-repo-stage"
SF_USER="${SF_USER:-visnudeva}"
SF_PROJECT="${SF_PROJECT:-sweetpotatos}"

# Same set spo-upgrade installs from GitHub.
OVERLAY_PKGS=(sweetpotatos swirl yay-bin shelly-bin localsend-bin spore waypaper brave-origin-bin)

rm -rf "${STAGE}"
mkdir -p "${STAGE}/x86_64"

copied=0
for pkg in "${OVERLAY_PKGS[@]}"; do
  shopt -s nullglob
  matches=("${REPO}/${pkg}"-*.pkg.tar.*)
  shopt -u nullglob
  for f in "${matches[@]}"; do
    base="$(basename "${f}")"
    [[ "${base}" == *-debug-* ]] && continue
    cp -a "${f}" "${STAGE}/x86_64/"
    copied=$((copied + 1))
  done
done

if (( copied == 0 )); then
  echo "No overlay packages in ${REPO}/ — build them first, then ./github/upload-repo.sh"
  exit 1
fi

echo "[*] Building SF bootstrap repo db (${copied} packages)…"
if command -v repo-add >/dev/null; then
  (
    cd "${STAGE}/x86_64"
    repo-add sweetpotatos.db.tar.gz ./*.pkg.tar.*
    cp -a sweetpotatos.db.tar.gz sweetpotatos.db
    [[ -f sweetpotatos.files.tar.gz ]] && cp -a sweetpotatos.files.tar.gz sweetpotatos.files
  )
else
  # Bluefin: reuse Arch container for repo-add
  podman run --rm --security-opt label=disable \
    -v "${STAGE}/x86_64:/stage:rw" -w /stage \
    docker.io/archlinux/archlinux:latest bash -euo pipefail -c '
pacman-key --init >/dev/null
pacman-key --populate archlinux
pacman -Sy --noconfirm >/dev/null
pacman -S --needed --noconfirm pacman-contrib >/dev/null
rm -f sweetpotatos.db* sweetpotatos.files*
repo-add sweetpotatos.db.tar.gz *.pkg.tar.*
rm -f sweetpotatos.db sweetpotatos.files
cp -a sweetpotatos.db.tar.gz sweetpotatos.db
cp -a sweetpotatos.files.tar.gz sweetpotatos.files
'
fi

FRS_ARCH="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/x86_64/"
FRS_FLAT="${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/repo/"
EMPTY="${ROOT}/sourceforge/empty-repo-stage"
SSH_CMD="${GIT_SSH_COMMAND:-ssh -i ${HOME}/.ssh/id_ed25519_sourceforge -o IdentitiesOnly=yes -o ServerAliveInterval=30}"

rm -rf "${EMPTY}"
mkdir -p "${EMPTY}"

# FRS shell cannot mkdir; create dirs by rsyncing an empty tree first.
echo "[*] Ensuring remote repo/ and repo/x86_64/ exist"
rsync -avP -e "${SSH_CMD}" "${EMPTY}/" "${FRS_FLAT}"
rsync -avP -e "${SSH_CMD}" "${EMPTY}/" "${FRS_ARCH}"

echo "[*] Uploading bootstrap overlay to ${FRS_ARCH}"
rsync -avP --delete -e "${SSH_CMD}" "${STAGE}/x86_64/" "${FRS_ARCH}"

echo "[*] Uploading flat repo/ mirror to ${FRS_FLAT}"
# Do not --delete the whole repo/ (would wipe x86_64/).
rsync -avP -e "${SSH_CMD}" \
  "${STAGE}/x86_64/"*.pkg.tar.* \
  "${STAGE}/x86_64/sweetpotatos.db" \
  "${STAGE}/x86_64/sweetpotatos.db.tar.gz" \
  "${STAGE}/x86_64/sweetpotatos.files" \
  "${STAGE}/x86_64/sweetpotatos.files.tar.gz" \
  "${FRS_FLAT}"

cat <<EOF

[+] SourceForge bootstrap overlay published.

Second Harvest systems with the old Server URL can spo-upgrade again.
Canonical overlay remains GitHub; new spo-upgrade migrates the Server line.

  https://downloads.sourceforge.net/project/${SF_PROJECT}/repo/x86_64/
EOF
