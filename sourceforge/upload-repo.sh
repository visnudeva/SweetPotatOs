#!/usr/bin/env bash
# Overlay packages are published to GitHub now (ISO downloads stay on SourceForge).
#
#   ./github/upload-repo.sh
#
# This wrapper remains so old docs / muscle memory keep working.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[*] Overlay pacman repo moved to GitHub — forwarding to github/upload-repo.sh"
exec "${ROOT}/github/upload-repo.sh" "$@"
