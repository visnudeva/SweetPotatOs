#!/usr/bin/env bash
# One-shot Arch container bootstrap + ISO build for SweetPotatOs (rootless-friendly).
set -euo pipefail

ROOT="/var/home/visnudeva/code/GITHUB/SweetPotatOs"
BUILD_USER="builder"

cd "${ROOT}"

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
  local build_dir="/home/${BUILD_USER}/build/${name}"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "/home/${BUILD_USER}/build"
  sudo -u "${BUILD_USER}" git clone --depth 1 "${aur_url}" "${build_dir}"
  sudo -u "${BUILD_USER}" bash -c "cd '${build_dir}' && makepkg -sr --noconfirm"
  mkdir -p "${ROOT}/repo"
  cp "${build_dir}"/*.pkg.tar.* "${ROOT}/repo/"
  echo "[+] ${name} copied to repo/"
}

build_swirl_to_repo() {
  local name="swirl"
  if ls "${ROOT}/repo/${name}"-*.pkg.tar.* >/dev/null 2>&1; then
    echo "[*] ${name} already in repo/ — skipping"
    return 0
  fi
  echo "[*] Building ${name} from packaging/swirl..."
  local build_dir="/home/${BUILD_USER}/build/${name}"
  rm -rf "${build_dir}"
  sudo -u "${BUILD_USER}" mkdir -p "/home/${BUILD_USER}/build"
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

echo "[*] Refreshing local repo database..."
rm -f "${ROOT}/repo/sweetpotatos".db* "${ROOT}/repo/sweetpotatos".files* 2>/dev/null || true
repo-add "${ROOT}/repo/sweetpotatos.db.tar.gz" "${ROOT}/repo"/*.pkg.tar.*

echo "[*] Building ISO via build.sh..."
# build.sh requires root + SUDO_USER for any remaining package builds; packages already present.
SUDO_USER="${BUILD_USER}" ./build.sh

echo "[+] Container build finished."
ls -lah "${ROOT}/out/" || true
