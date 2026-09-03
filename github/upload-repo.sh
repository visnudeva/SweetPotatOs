#!/usr/bin/env bash
# Publish the SweetPotatOs overlay pacman repo to a fixed GitHub Release
# (for spo-upgrade on installed systems). ISO downloads stay on SourceForge.
#
# Usage:
#   ./github/upload-repo.sh
#
# Release tag / download base (matches /etc/pacman.d/sweetpotatos.conf):
#   https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${ROOT}/repo"
STAGE="${ROOT}/github/repo-stage"
GH_REPO="${GH_REPO:-visnudeva/SweetPotatOs}"
GH_TAG="${GH_TAG:-pacman-repo}"
ARCH="${ARCH:-x86_64}"

# Packages spo-upgrade installs (not calamares / ISO-only build deps).
OVERLAY_PKGS=(sweetpotatos swirl yay-bin shelly-bin localsend-bin spore waypaper)

command -v gh >/dev/null || { echo "gh (GitHub CLI) is required"; exit 1; }
command -v repo-add >/dev/null || { echo "repo-add (pacman-contrib) is required"; exit 1; }

rm -rf "${STAGE}"
mkdir -p "${STAGE}"

copied=0
for pkg in "${OVERLAY_PKGS[@]}"; do
  shopt -s nullglob
  matches=("${REPO}/${pkg}"-*.pkg.tar.*)
  shopt -u nullglob
  for f in "${matches[@]}"; do
    base="$(basename "${f}")"
    # Skip debug packages
    [[ "${base}" == *-debug-* ]] && continue
    cp -a "${f}" "${STAGE}/"
    copied=$((copied + 1))
  done
done

if (( copied == 0 )); then
  echo "No overlay packages in ${REPO}/ — run: sudo ./build.sh --build-packages"
  exit 1
fi

echo "[*] Building overlay repo database (${copied} packages)…"
repo-add "${STAGE}/sweetpotatos.db.tar.gz" "${STAGE}"/*.pkg.tar.*
# Pacman / spo-upgrade fetch $repo.db (gzip); release assets need that name too.
cp -a "${STAGE}/sweetpotatos.db.tar.gz" "${STAGE}/sweetpotatos.db"
[[ -f "${STAGE}/sweetpotatos.files.tar.gz" ]] \
  && cp -a "${STAGE}/sweetpotatos.files.tar.gz" "${STAGE}/sweetpotatos.files"

if ! gh release view "${GH_TAG}" --repo "${GH_REPO}" >/dev/null 2>&1; then
  echo "[*] Creating GitHub release ${GH_TAG}…"
  gh release create "${GH_TAG}" \
    --repo "${GH_REPO}" \
    --title "SweetPotatOs pacman overlay repo" \
    --notes "Unsigned overlay packages for \`sudo spo-upgrade\` on installed systems. ISO downloads remain on SourceForge." \
    --latest=false
fi

echo "[*] Uploading assets to ${GH_REPO} @ ${GH_TAG}…"
# Upload one-by-one so a single large asset failure is obvious.
shopt -s nullglob
for f in "${STAGE}"/*; do
  [[ -f "${f}" ]] || continue
  [[ -L "${f}" ]] && continue
  echo "    $(basename "${f}")"
  gh release upload "${GH_TAG}" "${f}" --repo "${GH_REPO}" --clobber
done
shopt -u nullglob

cat <<EOF

[+] Overlay repo published to GitHub Release ${GH_TAG}.

Installed systems:
  sudo spo-upgrade

Download base:
  https://github.com/${GH_REPO}/releases/download/${GH_TAG}/

ISO uploads stay on SourceForge:
  SF_USER=… ./sourceforge/upload.sh
EOF
