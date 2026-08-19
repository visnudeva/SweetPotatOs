#!/usr/bin/env bash
# SweetPotatOs ISO build script — requires root.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${ROOT}/profile"
REPO="${ROOT}/repo"
WORK="${ROOT}/work"
OUT="${ROOT}/out"
AUR_USER="${SUDO_USER:-}"

need_repo_pkg() {
  local name="$1"
  ls "${REPO}/${name}"-*.pkg.tar.* >/dev/null 2>&1
}

ensure_local_repo_pacman() {
  mkdir -p "${REPO}"
  if [[ ! -f /etc/pacman.d/sweetpotatos-local.conf ]]; then
    cat >/etc/pacman.d/sweetpotatos-local.conf <<EOF
[sweetpotatos]
SigLevel = Optional TrustAll
Server = file://${REPO}
EOF
  else
    sed -i "s|^Server = file://.*|Server = file://${REPO}|" /etc/pacman.d/sweetpotatos-local.conf
  fi
  if ! grep -q '^Include = /etc/pacman.d/sweetpotatos-local.conf' /etc/pacman.conf \
    && ! grep -q '^\[sweetpotatos\]' /etc/pacman.conf; then
    printf '\nInclude = /etc/pacman.d/sweetpotatos-local.conf\n' >>/etc/pacman.conf
  fi
  if ls "${REPO}"/*.pkg.tar.* >/dev/null 2>&1; then
    repo-add -R "${REPO}/sweetpotatos.db.tar.gz" "${REPO}"/*.pkg.tar.* >/dev/null 2>&1 \
      || repo-add "${REPO}/sweetpotatos.db.tar.gz" "${REPO}"/*.pkg.tar.* >/dev/null 2>&1 || true
  fi
  pacman -Sy --noconfirm >/dev/null 2>&1 || true
}

build_local_pkg() {
  local name="$1"
  local srcdir="$2"
  if [[ -z "${AUR_USER}" || "${AUR_USER}" == "root" ]]; then
    echo "Run: sudo ./build.sh (from a normal user, not root login)." >&2
    exit 1
  fi
  ensure_local_repo_pacman
  echo "[*] Building ${name} into ${REPO}..."
  pacman -S --needed --noconfirm base-devel git meson ninja 2>/dev/null || true
  local build_dir="${ROOT}/.aur-build/${name}"
  mkdir -p "${ROOT}/.aur-build"
  rm -rf "${build_dir}"
  mkdir -p "${build_dir}"
  cp -a "${srcdir}/." "${build_dir}/"
  chown -R "${AUR_USER}:${AUR_USER}" "${ROOT}/.aur-build"
  sudo -u "${AUR_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm" || {
    echo "makepkg failed for ${name}; fix packaging/${name} or install the package into ${REPO}/ manually." >&2
    exit 1
  }
  cp "${build_dir}"/*.pkg.tar.* "${REPO}/"
  ensure_local_repo_pacman
  echo "[+] ${name} added to local repo."
}

build_aur_pkg() {
  local name="$1"
  local aur_url="$2"
  if [[ -z "${AUR_USER}" || "${AUR_USER}" == "root" ]]; then
    echo "Run: sudo ./build.sh --build-calamares (from a normal user, not root login)." >&2
    exit 1
  fi
  ensure_local_repo_pacman
  echo "[*] Building ${name} from AUR into ${REPO}..."
  local build_dir="${ROOT}/.aur-build/${name}"
  mkdir -p "${ROOT}/.aur-build"
  chown -R "${AUR_USER}:${AUR_USER}" "${ROOT}/.aur-build"
  pacman -S --needed --noconfirm base-devel git
  # Avoid interactive jack provider prompts when AUR deps pull in mpv/ffmpeg
  pacman -S --needed --noconfirm --asdeps pipewire-jack 2>/dev/null || true
  if [[ ! -d "${build_dir}/.git" ]]; then
    sudo -u "${AUR_USER}" git clone --depth 1 "${aur_url}" "${build_dir}"
  else
    sudo -u "${AUR_USER}" git -C "${build_dir}" pull --ff-only || true
  fi
  sudo -u "${AUR_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm" || {
    echo "makepkg failed; install ${name} into ${REPO}/ manually." >&2
    exit 1
  }
  shopt -s nullglob
  local built=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  if ((${#built[@]} == 0)); then
    echo "makepkg produced no packages for ${name}" >&2
    exit 1
  fi
  cp "${built[@]}" "${REPO}/"
  ensure_local_repo_pacman
  echo "[+] ${name} added to local repo."
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must be run as root (sudo ./build.sh)." >&2
  exit 1
fi

if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "[*] Installing archiso..."
  pacman -S --needed --noconfirm archiso
fi

mkdir -p "${REPO}" "${OUT}"

DO_CALAMARES=0
DO_SWIRL=0
DO_AUR_APPS=0
DO_ISO=1
for arg in "$@"; do
  case "${arg}" in
    --build-calamares) DO_CALAMARES=1; DO_ISO=0 ;;
    --build-swirl) DO_SWIRL=1; DO_ISO=0 ;;
    --build-aur-apps) DO_AUR_APPS=1; DO_ISO=0 ;;
    --build-packages) DO_CALAMARES=1; DO_SWIRL=1; DO_AUR_APPS=1; DO_ISO=0 ;;
    --help|-h)
      cat <<EOF
Usage: sudo ./build.sh [options]

  (no args)           Build ISO (requires calamares + swirl + AUR apps in repo/)
  --build-calamares   Build Calamares into repo/ only
  --build-swirl       Build Swirl compositor into repo/ only
  --build-aur-apps    Build yay-bin + shelly-bin + tera into repo/ only
  --build-packages    Build calamares + swirl + AUR apps into repo/ only
EOF
      exit 0
      ;;
  esac
done

# Auto-build missing packages when building the ISO
if (( DO_ISO )); then
  need_repo_pkg calamares || DO_CALAMARES=1
  need_repo_pkg swirl || DO_SWIRL=1
  need_repo_pkg yay-bin || DO_AUR_APPS=1
  need_repo_pkg shelly-bin || DO_AUR_APPS=1
  need_repo_pkg tera || DO_AUR_APPS=1
  need_repo_pkg waypaper || DO_AUR_APPS=1
fi

if (( DO_CALAMARES )) && ! need_repo_pkg calamares; then
  build_aur_pkg calamares https://aur.archlinux.org/calamares.git
elif (( DO_CALAMARES )); then
  echo "[*] calamares already in ${REPO}/ — skipping"
fi

if (( DO_SWIRL )) && ! need_repo_pkg swirl; then
  build_local_pkg swirl "${ROOT}/packaging/swirl"
elif (( DO_SWIRL )); then
  echo "[*] swirl already in ${REPO}/ — skipping"
fi

if (( DO_AUR_APPS )); then
  need_repo_pkg yay-bin || build_aur_pkg yay-bin https://aur.archlinux.org/yay-bin.git
  # Local PKGBUILD: AUR shelly-bin often blocked/empty behind Anubis; no zig needed
  need_repo_pkg shelly-bin || build_local_pkg shelly-bin "${ROOT}/packaging/shelly-bin"
  # Local PKGBUILD: AUR tera omits go makedepend required by upstream Makefile
  need_repo_pkg tera || build_local_pkg tera "${ROOT}/packaging/tera"
  need_repo_pkg waypaper || build_aur_pkg waypaper https://aur.archlinux.org/waypaper.git
fi

if ! need_repo_pkg calamares || ! need_repo_pkg swirl \
  || ! need_repo_pkg yay-bin || ! need_repo_pkg shelly-bin \
  || ! need_repo_pkg tera || ! need_repo_pkg waypaper; then
  cat >&2 <<EOF
[!] Local repo is missing required packages in ${REPO}/

Build them first:

  sudo ./build.sh --build-packages   # builds calamares, swirl, yay-bin, shelly-bin, tera, waypaper

EOF
  exit 1
fi

if [[ ! -f "${REPO}/sweetpotatos.db.tar.gz" ]]; then
  echo "[*] Initializing repo database..."
  repo-add "${REPO}/sweetpotatos.db.tar.gz" "${REPO}"/*.pkg.tar.* 2>/dev/null || true
fi

if (( ! DO_ISO )); then
  echo "[+] Packages ready in ${REPO}/"
  ls -la "${REPO}/"*.pkg.tar.* 2>/dev/null || true
  exit 0
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
