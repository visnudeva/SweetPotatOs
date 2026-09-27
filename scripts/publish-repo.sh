#!/usr/bin/env bash
# Publish local repo/ packages to a GitHub Release used as a pacman Server.
# SourceForge stays ISO + project web only — do not upload packages there.
#
# Usage (from SweetPotatOs root):
#   ./scripts/publish-repo.sh testing      # default workflow: pacman-repo-testing (prerelease)
#   ./scripts/publish-repo.sh              # stable/live tag pacman-repo (only when asked)
# Optional:
#   TAG=pacman-repo REPO=visnudeva/SweetPotatOs ./scripts/publish-repo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${ROOT}/repo"
GH_REPO="${REPO:-visnudeva/SweetPotatOs}"
STAGE="${ROOT}/.publish-repo-stage"
CHANNEL="${1:-stable}"

case "${CHANNEL}" in
  stable|live)
    TAG="${TAG:-pacman-repo}"
    TITLE="SweetPotatOs pacman repo"
    PRERELEASE=false
    ;;
  testing|test)
    # Explicit testing never follows a leftover TAG=pacman-repo.
    TAG=pacman-repo-testing
    TITLE="SweetPotatOs pacman repo (testing)"
    PRERELEASE=true
    ;;
  -h|--help)
    echo "Usage: $0 [stable|testing]" >&2
    exit 0
    ;;
  *)
    echo "Unknown channel: ${CHANNEL} (use stable or testing)" >&2
    exit 2
    ;;
esac
SERVER="https://github.com/${GH_REPO}/releases/download/${TAG}"

command -v gh >/dev/null 2>&1 || { echo "gh CLI required" >&2; exit 1; }
command -v repo-add >/dev/null 2>&1 || { echo "pacman-contrib (repo-add) required" >&2; exit 1; }

shopt -s nullglob
pkgs=("${REPO_DIR}"/*.pkg.tar.zst)
upload=()
for p in "${pkgs[@]}"; do
  base="$(basename "${p}")"
  case "${base}" in
    *-debug-*) continue ;;
    *) upload+=("${p}") ;;
  esac
done
if ((${#upload[@]} == 0)); then
  echo "No packages in ${REPO_DIR}/" >&2
  exit 1
fi

if [[ "${PRERELEASE}" == true ]]; then
  echo "[*] Channel: testing → ${TAG} (prerelease; live pacman-repo is left alone)"
else
  echo "[*] Channel: stable → ${TAG}"
fi
echo "[*] Staging ${#upload[@]} packages for ${GH_REPO} @ ${TAG}"
rm -rf "${STAGE}"
mkdir -p "${STAGE}"
cp -a "${upload[@]}" "${STAGE}/"

(
  cd "${STAGE}"
  rm -f sweetpotatos.db sweetpotatos.db.tar.gz sweetpotatos.db.tar.gz.old \
        sweetpotatos.files sweetpotatos.files.tar.gz sweetpotatos.files.tar.gz.old
  repo-add sweetpotatos.db.tar.gz ./*.pkg.tar.zst >/dev/null
  # Real files for GitHub Releases (no symlinks).
  rm -f sweetpotatos.db sweetpotatos.files
  cat sweetpotatos.db.tar.gz >sweetpotatos.db
  cat sweetpotatos.files.tar.gz >sweetpotatos.files
)

mapfile -d '' assets < <(find "${STAGE}" -maxdepth 1 -type f \( \
  -name '*.pkg.tar.zst' -o \
  -name 'sweetpotatos.db' -o \
  -name 'sweetpotatos.files' -o \
  -name 'sweetpotatos.db.tar.gz' -o \
  -name 'sweetpotatos.files.tar.gz' \
\) -print0)

if ((${#assets[@]} == 0)); then
  echo "Nothing to upload under ${STAGE}" >&2
  exit 1
fi
echo "[*] Uploading ${#assets[@]} assets…"

if [[ "${PRERELEASE}" == true ]]; then
  NOTES="$(cat <<EOF
Testing pacman channel for SweetPotatOs. Not for general installs.

Live systems stay on tag \`pacman-repo\`. This release is \`${TAG}\`.

On a test install: \`sudo sweetpotatos-update --testing\`
Back to live: \`sudo sweetpotatos-update --stable\`

\`\`\`ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = ${SERVER}
\`\`\`
EOF
)"
else
  NOTES="$(cat <<EOF
Pacman package channel for installed SweetPotatOs systems (not ISOs).

SourceForge Files stays ISO-only. Point pacman at:

\`\`\`ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = ${SERVER}
\`\`\`

Then: \`sudo sweetpotatos-update\`

Testing builds go to tag \`pacman-repo-testing\` (\`./scripts/publish-repo.sh testing\`).
EOF
)"
fi

if [[ "${PRERELEASE}" == true ]]; then
  create_flags=(--prerelease --latest=false)
  edit_flags=(--prerelease --latest=false)
else
  create_flags=(--latest)
  edit_flags=(--prerelease=false --latest)
fi

if gh release view "${TAG}" -R "${GH_REPO}" >/dev/null 2>&1; then
  echo "[*] Updating existing release ${TAG}"
  gh release upload "${TAG}" "${assets[@]}" -R "${GH_REPO}" --clobber
  gh release edit "${TAG}" -R "${GH_REPO}" --title "${TITLE}" --notes "${NOTES}" \
    "${edit_flags[@]}" >/dev/null
else
  echo "[*] Creating release ${TAG}"
  gh release create "${TAG}" "${assets[@]}" -R "${GH_REPO}" \
    --title "${TITLE}" \
    --notes "${NOTES}" \
    "${create_flags[@]}"
fi

echo "[+] Published to https://github.com/${GH_REPO}/releases/tag/${TAG}"
echo "    Server = https://github.com/${GH_REPO}/releases/download/${TAG}"
rm -rf "${STAGE}"
