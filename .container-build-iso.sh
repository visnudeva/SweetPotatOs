#!/usr/bin/env bash
# ISO-only build (packages already in repo/). Rootful container required for pacstrap mounts.
set -euo pipefail

ROOT="/var/home/visnudeva/code/GITHUB/SweetPotatOs"
BUILD_USER="builder"

cd "${ROOT}"

echo "[*] Initializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux

# Prefer stable mirrors; avoid flaky geo/fastly stalls during pacstrap.
cat >/etc/pacman.d/mirrorlist <<'EOF'
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
EOF
# Disable low-speed cutoffs that abort large package downloads mid-ISO build.
sed -i 's/^#\?DisableDownloadTimeout.*/DisableDownloadTimeout/' /etc/pacman.conf
grep -q '^DisableDownloadTimeout' /etc/pacman.conf || echo 'DisableDownloadTimeout' >>/etc/pacman.conf

echo "[*] Installing archiso..."
pacman -Syu --noconfirm
pacman -S --needed --noconfirm archiso base-devel git sudo

if ! id -u "${BUILD_USER}" >/dev/null 2>&1; then
  useradd -m -G wheel -s /bin/bash "${BUILD_USER}"
fi
mkdir -p /etc/sudoers.d
echo "${BUILD_USER} ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/build-user
chmod 440 /etc/sudoers.d/build-user

if [[ ! -f "${ROOT}/repo/sweetpotatos.db.tar.gz" ]]; then
  repo-add "${ROOT}/repo/sweetpotatos.db.tar.gz" "${ROOT}/repo"/*.pkg.tar.*
fi

echo "[*] Building ISO..."
SUDO_USER="${BUILD_USER}" ./build.sh

echo "[+] Done."
ls -lah "${ROOT}/out/"
