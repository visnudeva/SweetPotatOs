#!/usr/bin/env bash
# Publish local repo/ packages to a GitHub Release used as a pacman Server.
# SourceForge stays ISO + project web only — do not upload packages there.
#
# Usage (from SweetPotatOs root):
#   ./scripts/publish-repo.sh
# Optional:
#   TAG=pacman-repo REPO=visnudeva/SweetPotatOs ./scripts/publish-repo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${ROOT}/repo"
TAG="${TAG:-pacman-repo}"
GH_REPO="${REPO:-visnudeva/SweetPotatOs}"
STAGE="${ROOT}/.publish-repo-stage"

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

NOTES="$(cat <<'EOF'
Pacman package channel for installed SweetPotatOs systems (not ISOs).

SourceForge Files stays ISO-only. Point pacman at:

```ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo
```

Then: `sudo sweetpotatos-update`
EOF
)"

if gh release view "${TAG}" -R "${GH_REPO}" >/dev/null 2>&1; then
  echo "[*] Updating existing release ${TAG}"
  gh release upload "${TAG}" "${assets[@]}" -R "${GH_REPO}" --clobber
  gh release edit "${TAG}" -R "${GH_REPO}" --notes "${NOTES}" >/dev/null
else
  echo "[*] Creating release ${TAG}"
  gh release create "${TAG}" "${assets[@]}" -R "${GH_REPO}" \
    --title "SweetPotatOs pacman repo" \
    --notes "${NOTES}"
fi

echo "[+] Published to https://github.com/${GH_REPO}/releases/tag/${TAG}"
echo "    Server = https://github.com/${GH_REPO}/releases/download/${TAG}"
rm -rf "${STAGE}"
