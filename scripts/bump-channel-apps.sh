#!/usr/bin/env bash
# Check upstream versions for SPO channel apps, bump local PKGBUILDs when
# needed, rebuild into repo/, bump sweetpotatos pkgrel + update-news, and
# optionally publish to the testing channel.
#
# Usage (normal user, from SweetPotatOs root):
#   ./scripts/bump-channel-apps.sh                  # check + bump + rebuild
#   ./scripts/bump-channel-apps.sh --check-only     # print outdated only
#   ./scripts/bump-channel-apps.sh --apps brave,tuber
#   ./scripts/bump-channel-apps.sh --publish-testing
#   ./scripts/bump-channel-apps.sh --news "tuber font scaling; channel app refresh."
#
# Apps (default all):
#   brave     → packaging/brave-origin-bin  (GitHub brave-browser + origin zip)
#   shelly    → packaging/shelly-bin        (GitHub Seafoam-Labs/Shelly-ALPM)
#   localsend → packaging/localsend-bin     (GitHub localsend/localsend)
#   yay       → AUR yay-bin
#   waypaper  → AUR waypaper (+ deps if missing in repo/)
#   tuber     → packaging/tuber             (GitHub visnudeva/tuber, pinned commit)
#   spore     → packaging/spore             (GitHub visnudeva/spore, pinned commit)
#   laniakea  → packaging/laniakea          (GitHub visnudeva/swirl-laniakea)
#
# First-party apps must be bumped here so sweetpotatos-update can deliver them;
# the client only installs whatever is already published on the channel.
#
# Does not push to stable. Use ./scripts/ship-stable.sh after testing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib-spo.sh
source "${ROOT}/scripts/lib-spo.sh"

CHECK_ONLY=0
PUBLISH_TESTING=0
NEWS=""
APPS_CSV="brave,shelly,localsend,yay,waypaper,tuber,spore,laniakea"
DRY=0
FORCE_REBUILD=0

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=1; shift ;;
    --publish-testing) PUBLISH_TESTING=1; shift ;;
    --news) NEWS="${2:-}"; shift 2 ;;
    --apps) APPS_CSV="${2:-}"; shift 2 ;;
    --force-rebuild) FORCE_REBUILD=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage 0 ;;
    *) spo_die "Unknown arg: $1 (see --help)" ;;
  esac
done

if [[ "${EUID}" -eq 0 ]]; then
  spo_die "Run as your normal user (makepkg refuses root)."
fi

spo_need git
spo_need curl
spo_need python3
spo_need makepkg
spo_need gh

IFS=',' read -r -a APPS <<< "${APPS_CSV}"
CHANGED=()
NOTES=()

ver_gt() {
  # true if $1 is newer than $2 (pacman vercmp)
  [[ "$(vercmp "$1" "$2")" -gt 0 ]]
}

bump_brave() {
  local pb="${ROOT}/packaging/brave-origin-bin/PKGBUILD"
  local cur latest
  cur="$(spo_pkgbuild_get "${pb}" pkgver)"
  latest="$(spo_gh_latest_tag brave/brave-browser brave-origin-)"
  [[ -n "${latest}" ]] || spo_die "Could not resolve latest brave-origin release"
  echo "[*] brave-origin-bin: ${cur} → ${latest}"
  if ! ver_gt "${latest}" "${cur}" && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY )); then
    CHANGED+=("brave-origin-bin ${cur}→${latest}")
    return 0
  fi
  if (( DRY )); then
    echo "    dry-run: bump PKGBUILD + rebuild"
    CHANGED+=("brave-origin-bin ${cur}→${latest}")
    return 0
  fi
  spo_pkgbuild_set_pkgver "${pb}" "${latest}"
  spo_pkgbuild_regen_sums "${ROOT}/packaging/brave-origin-bin"
  spo_makepkg_local "${ROOT}" brave-origin-bin
  CHANGED+=("brave-origin-bin ${cur}→${latest}")
  NOTES+=("Brave Origin ${latest}")
}

bump_shelly() {
  local pb="${ROOT}/packaging/shelly-bin/PKGBUILD"
  local cur latest
  cur="$(spo_pkgbuild_get "${pb}" pkgver)"
  latest="$(spo_gh_latest_tag Seafoam-Labs/Shelly-ALPM)"
  [[ -n "${latest}" ]] || spo_die "Could not resolve latest Shelly release"
  echo "[*] shelly-bin: ${cur} → ${latest}"
  if ! ver_gt "${latest}" "${cur}" && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY || DRY )); then
    CHANGED+=("shelly-bin ${cur}→${latest}")
    (( DRY )) && echo "    dry-run: bump PKGBUILD + rebuild"
    return 0
  fi
  spo_pkgbuild_set_pkgver "${pb}" "${latest}"
  spo_pkgbuild_regen_sums "${ROOT}/packaging/shelly-bin"
  spo_makepkg_local "${ROOT}" shelly-bin
  CHANGED+=("shelly-bin ${cur}→${latest}")
  NOTES+=("Shelly ${latest}")
}

bump_localsend() {
  local pb="${ROOT}/packaging/localsend-bin/PKGBUILD"
  local cur latest
  cur="$(spo_pkgbuild_get "${pb}" pkgver)"
  latest="$(spo_gh_latest_tag localsend/localsend)"
  [[ -n "${latest}" ]] || spo_die "Could not resolve latest LocalSend release"
  echo "[*] localsend-bin: ${cur} → ${latest}"
  if ! ver_gt "${latest}" "${cur}" && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY || DRY )); then
    CHANGED+=("localsend-bin ${cur}→${latest}")
    (( DRY )) && echo "    dry-run: bump PKGBUILD + rebuild"
    return 0
  fi
  spo_pkgbuild_set_pkgver "${pb}" "${latest}"
  spo_pkgbuild_regen_sums "${ROOT}/packaging/localsend-bin"
  spo_makepkg_local "${ROOT}" localsend-bin
  CHANGED+=("localsend-bin ${cur}→${latest}")
  NOTES+=("LocalSend ${latest}")
}

# AUR packages: compare Version in AUR vs newest package in repo/ (or skip if absent).
repo_pkgver() {
  local name="$1"
  local f
  f="$(ls -1 "${ROOT}/repo/${name}"-*.pkg.tar.* 2>/dev/null | grep -v -- '-debug-' | sort -V | tail -1 || true)"
  [[ -n "${f}" ]] || { echo ""; return 0; }
  # name-1.2.3-1-x86_64.pkg.tar.zst → 1.2.3
  basename "${f}" | sed -E "s/^${name}-([^-]+)-[0-9]+-.*/\1/"
}

bump_aur() {
  local short="$1" name="$2" url="$3"
  local cur latest
  cur="$(repo_pkgver "${name}")"
  latest="$(spo_aur_pkgver "${name}")"
  [[ -n "${latest}" ]] || spo_die "AUR has no ${name}"
  echo "[*] ${name}: repo=${cur:-none} aur=${latest}"
  if [[ -n "${cur}" ]] && ! ver_gt "${latest}" "${cur}" && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY || DRY )); then
    CHANGED+=("${name} ${cur:-none}→${latest}")
    (( DRY )) && echo "    dry-run: rebuild from AUR"
    return 0
  fi
  if [[ "${name}" == waypaper ]]; then
    # Ensure AUR deps exist in repo/ and on the host for makepkg.
    if ! ls "${ROOT}/repo"/python-screeninfo-*.pkg.tar.* >/dev/null 2>&1; then
      spo_makepkg_aur "${ROOT}" python-screeninfo https://aur.archlinux.org/python-screeninfo.git
    fi
    if ! ls "${ROOT}/repo"/python-imageio-ffmpeg-*.pkg.tar.* >/dev/null 2>&1; then
      spo_makepkg_aur "${ROOT}" python-imageio-ffmpeg https://aur.archlinux.org/python-imageio-ffmpeg.git
    fi
    sudo pacman -U --needed --noconfirm \
      "${ROOT}/repo"/python-screeninfo-*.pkg.tar.* \
      "${ROOT}/repo"/python-imageio-ffmpeg-*.pkg.tar.* 2>/dev/null || true
  fi
  spo_makepkg_aur "${ROOT}" "${name}" "${url}"
  CHANGED+=("${name} ${cur:-none}→${latest}")
  NOTES+=("${short} ${latest}")
}

# Pin packaging/<name> to the tip of a GitHub repo (source=…#commit=…).
# Rebuilds when GitHub moved OR repo/ still has an older package.
bump_git_pin() {
  local name="$1" repo="$2" label="${3:-$1}"
  local pb="${ROOT}/packaging/${name}/PKGBUILD"
  local cur latest short repo_ver repo_hash
  [[ -f "${pb}" ]] || spo_die "Missing ${pb}"
  cur="$(grep -oE '#commit=[0-9a-f]{7,40}' "${pb}" | head -1 | cut -d= -f2 || true)"
  latest="$(spo_gh_latest_commit "${repo}")"
  [[ -n "${latest}" ]] || spo_die "Could not resolve ${repo} HEAD"
  short="$(printf '%s' "${latest}" | cut -c1-7)"
  repo_ver="$(repo_pkgver "${name}")"
  repo_hash="$(printf '%s' "${repo_ver}" | grep -oE 'g[0-9a-f]+$' | cut -c2- || true)"
  echo "[*] ${name}: pin=${cur:-none} repo=${repo_ver:-none} → ${short}"
  if [[ -n "${cur}" && ( "${cur}" == "${latest}" || "${cur}" == "${short}" ) \
      && -n "${repo_hash}" && ( "${repo_hash}" == "${short}" || "${latest}" == "${repo_hash}"* ) \
      ]] && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY || DRY )); then
    CHANGED+=("${name} ${repo_ver:-${cur:-none}}→${short}")
    (( DRY )) && echo "    dry-run: pin commit + rebuild"
    return 0
  fi
  if grep -qE '#commit=[0-9a-f]+' "${pb}"; then
    sed -i -E "s|#commit=[0-9a-f]+|#commit=${latest}|" "${pb}"
  else
    spo_die "${pb}: expected source=…#commit=… pin"
  fi
  sed -i -E 's/^pkgrel=.*/pkgrel=1/' "${pb}"
  spo_makepkg_local "${ROOT}" "${name}"
  # makepkg refreshes pkgver= via pkgver(); read it back for the note.
  local ver
  ver="$(spo_pkgbuild_get "${pb}" pkgver)"
  CHANGED+=("${name} ${repo_ver:-${cur:-none}}→${ver}")
  NOTES+=("${label} ${ver}")
}

# Rebuild packaging/<name> when GitHub main moved (source=…#branch=main).
bump_git_branch() {
  local name="$1" repo="$2" label="${3:-$1}"
  local pb="${ROOT}/packaging/${name}/PKGBUILD"
  local cur_ver cur_hash latest short repo_ver repo_hash
  [[ -f "${pb}" ]] || spo_die "Missing ${pb}"
  cur_ver="$(spo_pkgbuild_get "${pb}" pkgver)"
  cur_hash="$(printf '%s' "${cur_ver}" | grep -oE 'g[0-9a-f]+$' | cut -c2- || true)"
  repo_ver="$(repo_pkgver "${name}")"
  repo_hash="$(printf '%s' "${repo_ver}" | grep -oE 'g[0-9a-f]+$' | cut -c2- || true)"
  latest="$(spo_gh_latest_commit "${repo}")"
  [[ -n "${latest}" ]] || spo_die "Could not resolve ${repo} HEAD"
  short="$(printf '%s' "${latest}" | cut -c1-7)"
  echo "[*] ${name}: pkgbuild=${cur_ver} repo=${repo_ver:-none} → ${short}"
  if [[ -n "${cur_hash}" && ( "${cur_hash}" == "${short}" || "${latest}" == "${cur_hash}"* ) \
      && -n "${repo_hash}" && ( "${repo_hash}" == "${short}" || "${latest}" == "${repo_hash}"* ) \
      ]] && (( ! FORCE_REBUILD )); then
    echo "    up to date"
    return 0
  fi
  if (( CHECK_ONLY || DRY )); then
    CHANGED+=("${name} ${repo_ver:-${cur_ver}}→${short}")
    (( DRY )) && echo "    dry-run: rebuild from ${repo}"
    return 0
  fi
  sed -i -E 's/^pkgrel=.*/pkgrel=1/' "${pb}"
  spo_makepkg_local "${ROOT}" "${name}"
  local ver
  ver="$(spo_pkgbuild_get "${pb}" pkgver)"
  CHANGED+=("${name} ${repo_ver:-${cur_ver}}→${ver}")
  NOTES+=("${label} ${ver}")
}

cd "${ROOT}"

for app in "${APPS[@]}"; do
  app="$(echo "${app}" | tr -d '[:space:]')"
  [[ -n "${app}" ]] || continue
  case "${app}" in
    brave|brave-origin|brave-origin-bin) bump_brave ;;
    shelly|shelly-bin) bump_shelly ;;
    localsend|localsend-bin) bump_localsend ;;
    yay|yay-bin) bump_aur Yay yay-bin https://aur.archlinux.org/yay-bin.git ;;
    waypaper) bump_aur Waypaper waypaper https://aur.archlinux.org/waypaper.git ;;
    tuber) bump_git_pin tuber visnudeva/tuber tuber ;;
    spore) bump_git_pin spore visnudeva/spore spore ;;
    laniakea) bump_git_branch laniakea visnudeva/swirl-laniakea Laniakea ;;
    *) spo_die "Unknown app: ${app} (brave|shelly|localsend|yay|waypaper|tuber|spore|laniakea)" ;;
  esac
done

if ((${#CHANGED[@]} == 0)); then
  echo "[+] All selected apps are current."
  exit 0
fi

echo "[*] Changes:"
printf '    - %s\n' "${CHANGED[@]}"

if (( CHECK_ONLY )); then
  exit 0
fi

if (( DRY )); then
  echo "[*] dry-run complete (no rebuild / news / publish)."
  exit 0
fi

spo_repo_add_refresh "${ROOT}"

# Bump sweetpotatos so update-news can fire on installed systems.
pb="${ROOT}/packaging/sweetpotatos/PKGBUILD"
new_rel="$(spo_bump_pkgrel "${pb}")"
ver="$(spo_pkgbuild_get "${pb}" pkgver)-${new_rel}"
if [[ -z "${NEWS}" ]]; then
  NEWS="$(printf '%s, ' "${NOTES[@]}" | sed 's/, $//')."
  NEWS="Channel app refresh: ${NEWS}"
fi
spo_sweetpotatos_news "${ROOT}" "${ver}" "${NEWS}"
echo "[*] Rebuild sweetpotatos ${ver}"
spo_makepkg_local "${ROOT}" sweetpotatos
spo_repo_add_refresh "${ROOT}"

if (( PUBLISH_TESTING )); then
  echo "[*] Publish testing channel"
  ./scripts/publish-repo.sh testing
  echo "    On an SPO box: sudo sweetpotatos-update --testing"
else
  echo "[*] Packages in repo/. Publish when ready:"
  echo "      ./scripts/publish-repo.sh testing"
  echo "    Or ship live (after testing):"
  echo "      ./scripts/ship-stable.sh --en \"${NEWS}\""
fi

echo "[+] bump-channel-apps done (${#CHANGED[@]} app update(s), sweetpotatos ${ver})."
