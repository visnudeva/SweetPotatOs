#!/usr/bin/env bash
# One-shot Arch container bootstrap + ISO build for SweetPotatOs (rootless-friendly).
set -euo pipefail

ROOT="/var/home/visnudeva/code/GITHUB/SweetPotatOs"
BUILD_USER="builder"
BUILD_ROOT="${ROOT}/.container-build"

cd "${ROOT}"
mkdir -p "${BUILD_ROOT}"

echo "[*] Initializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux

echo "[*] Updating system and installing build deps..."
pacman -Syu --noconfirm
pacman -S --needed --noconfirm archiso base-devel git sudo

if ! id -u "${BUILD_USER}" >/dev/null 2>&1; then
  echo "[*] Creating build user ${BUILD_USER}..."
  useradd -m -G wheel -s /bin/bash "${BUILD_USER}"
fi

mkdir -p /etc/sudoers.d
echo "${BUILD_USER} ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/build-user
chmod 440 /etc/sudoers.d/build-user

# Build AUR/local packages in container-local dirs (bind mounts often root-owned in rootless).
# Then copy artifacts into the mounted repo/.
build_aur_to_repo() {
  local name="$1"
  local aur_url="$2"
  if ls "${ROOT}/repo/${name}"-*.pkg.tar.* >/dev/null 2>&1; then
    echo "[*] ${name} already in repo/ — skipping"
    return 0
  fi
  echo "[*] Building ${name} from AUR..."
  local build_dir="${BUILD_ROOT}/${name}"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  sudo -u "${BUILD_USER}" git clone --depth 1 "${aur_url}" "${build_dir}"
  # Refresh local repo so earlier AUR builds resolve as deps if needed
  if ls "${ROOT}/repo"/*.pkg.tar.* >/dev/null 2>&1; then
    rm -f "${ROOT}/repo/sweetpotatos".db* "${ROOT}/repo/sweetpotatos".files* 2>/dev/null || true
    repo-add "${ROOT}/repo/sweetpotatos.db.tar.gz" "${ROOT}/repo"/*.pkg.tar.*
    if ! grep -q '^\[sweetpotatos\]' /etc/pacman.conf; then
      cat >>/etc/pacman.conf <<EOF

[sweetpotatos]
SigLevel = Optional TrustAll
Server = file://${ROOT}/repo
EOF
    fi
    pacman -Sy --noconfirm
  fi
  # Prefer pipewire-jack so mpv/ffmpeg deps do not prompt for a jack provider
  pacman -S --needed --noconfirm --asdeps pipewire-jack 2>/dev/null || true
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  shopt -s nullglob
  local pkgs=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  if ((${#pkgs[@]} == 0)); then
    echo "[!] makepkg produced no packages for ${name}" >&2
    exit 1
  fi
  mkdir -p "${ROOT}/repo"
  cp "${pkgs[@]}" "${ROOT}/repo/"
  echo "[+] ${name} copied to repo/"
}

build_swirl_to_repo() {
  local name="swirl"
  if ls "${ROOT}/repo/${name}"-*.pkg.tar.* >/dev/null 2>&1; then
    echo "[*] ${name} already in repo/ — skipping"
    return 0
  fi
  echo "[*] Building ${name} from packaging/swirl..."
  local build_dir="${BUILD_ROOT}/${name}"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  cp -a "${ROOT}/packaging/swirl/." "${build_dir}/"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${build_dir}"
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  mkdir -p "${ROOT}/repo"
  cp "${build_dir}"/*.pkg.tar.* "${ROOT}/repo/"
  echo "[+] ${name} copied to repo/"
}

echo "[*] Building packages into repo/..."
build_aur_to_repo calamares https://aur.archlinux.org/calamares.git
build_swirl_to_repo
build_aur_to_repo yay-bin https://aur.archlinux.org/yay-bin.git
# shelly-bin: local PKGBUILD (AUR clone often empty behind Anubis; no zig)
if ! ls "${ROOT}/repo/shelly-bin"-*.pkg.tar.* >/dev/null 2>&1; then
  echo "[*] Building shelly-bin from packaging/shelly-bin..."
  build_dir="${BUILD_ROOT}/shelly-bin-local"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  cp -a "${ROOT}/packaging/shelly-bin/." "${build_dir}/"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${build_dir}"
  pacman -S --needed --noconfirm --asdeps go-md2man
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  shopt -s nullglob
  pkgs=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#pkgs[@]})) || { echo "[!] shelly-bin build produced no packages" >&2; exit 1; }
  cp "${pkgs[@]}" "${ROOT}/repo/"
  echo "[+] shelly-bin copied to repo/"
fi
if ! ls "${ROOT}/repo/localsend-bin"-*.pkg.tar.* >/dev/null 2>&1; then
  echo "[*] Building localsend-bin from packaging/localsend-bin..."
  build_dir="${BUILD_ROOT}/localsend-bin-local"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  cp -a "${ROOT}/packaging/localsend-bin/." "${build_dir}/"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${build_dir}"
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  shopt -s nullglob
  pkgs=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#pkgs[@]})) || { echo "[!] localsend-bin build produced no packages" >&2; exit 1; }
  cp "${pkgs[@]}" "${ROOT}/repo/"
  echo "[+] localsend-bin copied to repo/"
fi

if ! ls "${ROOT}/repo/spore"-*.pkg.tar.* >/dev/null 2>&1; then
  echo "[*] Building spore from packaging/spore..."
  build_dir="${BUILD_ROOT}/spore-local"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  cp -a "${ROOT}/packaging/spore/." "${build_dir}/"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${build_dir}"
  pacman -S --needed --noconfirm go gcc alsa-lib
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  shopt -s nullglob
  pkgs=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#pkgs[@]})) || { echo "[!] spore build produced no packages" >&2; exit 1; }
  cp "${pkgs[@]}" "${ROOT}/repo/"
  echo "[+] spore copied to repo/"
fi

if ! ls "${ROOT}/repo/sweetpotatos"-*.pkg.tar.* >/dev/null 2>&1; then
  echo "[*] Building sweetpotatos from packaging/sweetpotatos..."
  build_dir="${BUILD_ROOT}/sweetpotatos-local"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "${BUILD_ROOT}"
  cp -a "${ROOT}/packaging/sweetpotatos/." "${build_dir}/"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${build_dir}"
  sudo -u "${BUILD_USER}" env SWEETPOTATOS_ROOT="${ROOT}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  shopt -s nullglob
  pkgs=( "${build_dir}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#pkgs[@]})) || { echo "[!] sweetpotatos build produced no packages" >&2; exit 1; }
  cp "${pkgs[@]}" "${ROOT}/repo/"
  echo "[+] sweetpotatos copied to repo/"
fi

build_aur_to_repo python-screeninfo https://aur.archlinux.org/python-screeninfo.git
build_aur_to_repo python-imageio-ffmpeg https://aur.archlinux.org/python-imageio-ffmpeg.git
build_aur_to_repo waypaper https://aur.archlinux.org/waypaper.git

echo "[*] Refreshing local repo database..."
rm -f "${ROOT}/repo/sweetpotatos".db* "${ROOT}/repo/sweetpotatos".files* 2>/dev/null || true
repo-add "${ROOT}/repo/sweetpotatos.db.tar.gz" "${ROOT}/repo"/*.pkg.tar.*

echo "[*] Building ISO via build.sh..."
# build.sh requires root + SUDO_USER for any remaining package builds; packages already present.
SUDO_USER="${BUILD_USER}" ./build.sh

echo "[+] Container build finished."
ls -lah "${ROOT}/out/" || true
