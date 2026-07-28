#!/usr/bin/env bash
# SweetPotatOs ISO build script — requires root.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${ROOT}/profile"
REPO="${ROOT}/repo"
WORK="${ROOT}/work"
OUT="${ROOT}/out"

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must be run as root (sudo ./build.sh)." >&2
  exit 1
fi

if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "[*] Installing archiso..."
  pacman -S --needed --noconfirm archiso
fi

mkdir -p "${REPO}" "${OUT}"

if ! ls "${REPO}"/*.pkg.tar.* >/dev/null 2>&1; then
  if [[ "${1:-}" == "--build-calamares" ]]; then
    echo "[*] Building calamares from AUR into ${REPO}..."
    AUR_USER="${SUDO_USER:-}"
    if [[ -z "${AUR_USER}" || "${AUR_USER}" == "root" ]]; then
      echo "Run: sudo ./build.sh --build-calamares (from a normal user, not root login)." >&2
      exit 1
    fi
    BUILD_DIR="${ROOT}/.aur-build/calamares"
    mkdir -p "${ROOT}/.aur-build"
    chown -R "${AUR_USER}:${AUR_USER}" "${ROOT}/.aur-build"
    pacman -S --needed --noconfirm base-devel git
    if [[ ! -d "${BUILD_DIR}/.git" ]]; then
      sudo -u "${AUR_USER}" git clone --depth 1 https://aur.archlinux.org/calamares.git "${BUILD_DIR}"
    else
      sudo -u "${AUR_USER}" git -C "${BUILD_DIR}" pull --ff-only || true
    fi
    sudo -u "${AUR_USER}" bash -c "cd '${BUILD_DIR}' && makepkg -sr --noconfirm" || {
      echo "makepkg failed; install calamares into ${REPO}/ manually." >&2
      exit 1
    }
    cp "${BUILD_DIR}"/*.pkg.tar.* "${REPO}/"
    repo-add "${REPO}/sweetpotatoos.db.tar.gz" "${REPO}"/*.pkg.tar.*
    echo "[+] calamares added to local repo."
  else
    cat >&2 <<EOF
[!] No packages in ${REPO}/

Calamares is not in official Arch repos. Build it into the local repo first:

  sudo ./build.sh --build-calamares

EOF
    exit 1
  fi
fi

if [[ ! -f "${REPO}/sweetpotatoos.db.tar.gz" ]]; then
  echo "[*] Initializing repo database..."
  repo-add "${REPO}/sweetpotatoos.db.tar.gz" "${REPO}"/*.pkg.tar.* 2>/dev/null || true
fi

echo "[*] Building SweetPotatOs ISO (profile: ${PROFILE})..."
# Fresh work tree avoids leftover overlay/package file conflicts from failed builds
rm -rf "${WORK}"
PACMAN_CONF="${PROFILE}/pacman.conf"
PACMAN_BACKUP="$(mktemp)"
cp "${PACMAN_CONF}" "${PACMAN_BACKUP}"
sed -i "s|^Server = file://.*|Server = file://${REPO}|" "${PACMAN_CONF}"
trap 'mv -f "${PACMAN_BACKUP}" "${PACMAN_CONF}"' EXIT
mkarchiso -v -w "${WORK}" -o "${OUT}" "${PROFILE}"
mv -f "${PACMAN_BACKUP}" "${PACMAN_CONF}"
trap - EXIT

echo
echo "[+] Done. ISO(s) in: ${OUT}/"
ls -la "${OUT}/" 2>/dev/null || true
