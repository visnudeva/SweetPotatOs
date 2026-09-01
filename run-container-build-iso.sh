#!/usr/bin/env bash
# ISO-only build (packages must already be in repo/). See run-container-build.sh for full build.
# mkarchiso/pacstrap needs rootful podman — rootless cannot mount /dev in the chroot.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${ROOT}/repo" "${ROOT}/out" "${ROOT}/work"

if [[ "${EUID}" -ne 0 ]]; then
  echo "[!] ISO build requires rootful podman. Re-run: sudo $0" >&2
  exit 1
fi

podman run --rm --privileged \
  --security-opt seccomp=unconfined \
  --security-opt label=disable \
  -v /dev:/dev \
  -v "${ROOT}:${ROOT}:O" \
  -v "${ROOT}/repo:${ROOT}/repo" \
  -v "${ROOT}/out:${ROOT}/out" \
  -v "${ROOT}/work:${ROOT}/work:rshared" \
  -w "${ROOT}" \
  docker.io/archlinux/archlinux:latest bash .container-build-iso.sh 2>&1 | tee "${ROOT}/out-build-second-harvest.log"
