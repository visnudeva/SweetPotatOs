#!/usr/bin/env bash
# Fedora/Bluefin host: build SweetPotatOs ISO in an Arch container.
# Full build ends with mkarchiso — use: sudo ./run-container-build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${ROOT}/.container-build" "${ROOT}/repo" "${ROOT}/out" "${ROOT}/work"

if [[ "${EUID}" -ne 0 ]]; then
  echo "[!] ISO stage needs rootful podman. Re-run: sudo $0" >&2
  exit 1
fi

podman run --rm --privileged \
  --security-opt seccomp=unconfined \
  --security-opt label=disable \
  -v /dev:/dev \
  -v "${ROOT}:${ROOT}:O" \
  -v "${ROOT}/.container-build:${ROOT}/.container-build" \
  -v "${ROOT}/repo:${ROOT}/repo" \
  -v "${ROOT}/out:${ROOT}/out" \
  -v "${ROOT}/work:${ROOT}/work:rshared" \
  -w "${ROOT}" \
  docker.io/archlinux/archlinux:latest bash .container-build.sh 2>&1 | tee "${ROOT}/out-build-second-harvest.log"
