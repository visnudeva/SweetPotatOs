#!/usr/bin/env bash
# Build a SweetPotatOs ISO, rename it, write a .sha256, optionally upload
# to SourceForge Files + project web.
#
# Usage (normal user — sudo is invoked for mkarchiso):
#   ./scripts/make-iso.sh
#   ./scripts/make-iso.sh --fifth                 # 2026.12 Fifth Harvest
#   ./scripts/make-iso.sh --sixth                 # 2027.01 Sixth Harvest
#   ./scripts/make-iso.sh --harvest seventh       # same idea for any ordinal
#   ./scripts/make-iso.sh --release 2027.01_Sixth_Harvest \
#                        --label SPOTATO_SIXTH202701 \
#                        --application "SweetPotatOs 2027.01 Sixth Harvest"
#   ./scripts/make-iso.sh --upload                # after build: sourceforge/upload.sh
#   ./scripts/make-iso.sh --skip-packages         # do not auto-build missing pkgs
#
# Harvest calendar (First = 2026.08, then +1 month each):
#   first… → 2026.08, …, fifth → 2026.12, sixth → 2027.01, …
#
# Env (also set by flags):
#   SF_USER / SF_SSH_KEY   for --upload
#   SF_RELEASE / ISO_NAME  forwarded to sourceforge/upload.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib-spo.sh
source "${ROOT}/scripts/lib-spo.sh"

RELEASE=""
LABEL=""
APPLICATION=""
ISO_BASENAME=""
DO_UPLOAD=0
SKIP_PACKAGES=0
DRY=0
HARVEST=""

usage() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

# Map ordinal word → 1-based index. Returns empty if unknown.
harvest_index() {
  python3 -c 'import sys
words="first second third fourth fifth sixth seventh eighth ninth tenth eleventh twelfth thirteenth fourteenth fifteenth".split()
w=sys.argv[1].lower().strip()
print(words.index(w)+1 if w in words else "")
' "$1"
}

harvest_title() {
  python3 -c 'print(sys.argv[1].lower().capitalize())' "$1" 2>/dev/null \
    || python3 -c 'import sys; print(sys.argv[1][:1].upper()+sys.argv[1][1:].lower())' "$1"
}

# First Harvest = 2026-08; Nth = that month + (N-1).
apply_harvest_preset() {
  local word="$1"
  local idx y m ym upper title
  idx="$(harvest_index "${word}")"
  [[ -n "${idx}" ]] || spo_die "Unknown harvest '${word}' (use first…fifteenth, or --release/--label/--application)"
  # month number from Aug 2026
  m=$((7 + idx))  # Aug=8 → first: 7+1=8
  y=2026
  while ((m > 12)); do
    m=$((m - 12))
    y=$((y + 1))
  done
  ym="$(printf '%04d.%02d' "${y}" "${m}")"
  title="$(harvest_title "${word}")"
  upper="$(echo "${word}" | tr '[:lower:]' '[:upper:]')"
  RELEASE="${RELEASE:-${ym}_${title}_Harvest}"
  LABEL="${LABEL:-SPOTATO_${upper}$(printf '%04d%02d' "${y}" "${m}")}"
  APPLICATION="${APPLICATION:-SweetPotatOs ${ym} ${title} Harvest}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --first|--second|--third|--fourth|--fifth|--sixth|--seventh|--eighth|--ninth|--tenth|--eleventh|--twelfth)
      HARVEST="${1#--}"
      shift
      ;;
    --harvest)
      HARVEST="${2:-}"
      [[ -n "${HARVEST}" ]] || spo_die "--harvest needs a name (e.g. sixth)"
      shift 2
      ;;
    --release) RELEASE="${2:-}"; shift 2 ;;
    --label) LABEL="${2:-}"; shift 2 ;;
    --application) APPLICATION="${2:-}"; shift 2 ;;
    --name) ISO_BASENAME="${2:-}"; shift 2 ;;
    --upload) DO_UPLOAD=1; shift ;;
    --skip-packages) SKIP_PACKAGES=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage 0 ;;
    *) spo_die "Unknown arg: $1 (see --help)" ;;
  esac
done

if [[ -n "${HARVEST}" ]]; then
  apply_harvest_preset "${HARVEST}"
fi

# Default: keep whatever profiledef.sh already says.
if [[ -z "${RELEASE}" ]]; then
  RELEASE="$(grep -E '^iso_version=' "${ROOT}/profile/profiledef.sh" | cut -d= -f2- | tr -d '"')"
fi
if [[ -z "${LABEL}" ]]; then
  LABEL="$(grep -E '^iso_label=' "${ROOT}/profile/profiledef.sh" | cut -d= -f2- | tr -d '"')"
fi
if [[ -z "${APPLICATION}" ]]; then
  APPLICATION="$(grep -E '^iso_application=' "${ROOT}/profile/profiledef.sh" | cut -d= -f2- | tr -d '"')"
fi
ISO_BASENAME="${ISO_BASENAME:-Sweetpotatos_${RELEASE}.iso}"

echo "[*] ISO identity"
echo "    release:     ${RELEASE}"
echo "    label:       ${LABEL}"
echo "    application: ${APPLICATION}"
echo "    filename:    ${ISO_BASENAME}"

if (( DRY )); then
  echo "[*] dry-run: would update profiledef, sudo ./build.sh, sha256, upload=${DO_UPLOAD}"
  exit 0
fi

spo_set_iso_identity "${ROOT}" "${RELEASE}" "${LABEL}" "${APPLICATION}"

if (( ! SKIP_PACKAGES )); then
  echo "[*] Ensure packages in repo/ (sudo ./build.sh --build-packages if missing)"
  missing=0
  for p in calamares swirl sweetpotatos yay-bin shelly-bin localsend-bin \
           spore tuber swaylock-effects brave-origin-bin waypaper; do
    ls "${ROOT}/repo/${p}"-*.pkg.tar.* >/dev/null 2>&1 || missing=1
  done
  if (( missing )); then
    echo "[*] Building missing packages…"
    sudo ./build.sh --build-packages
  else
    echo "    repo/ already has required packages"
  fi
fi

echo "[*] Building ISO (sudo ./build.sh)…"
cd "${ROOT}"
export SWEETPOTATOS_ISO_NAME="${ISO_BASENAME}"
sudo --preserve-env=SWEETPOTATOS_ISO_NAME ./build.sh

ISO_PATH="${ROOT}/out/${ISO_BASENAME}"
if [[ ! -f "${ISO_PATH}" ]]; then
  latest="$(find "${ROOT}/out" -maxdepth 1 -name '*.iso' -type f -printf '%T@ %p\n' \
    | sort -rn | head -1 | cut -d' ' -f2-)"
  [[ -n "${latest}" ]] || spo_die "No ISO in out/"
  if [[ "$(basename "${latest}")" != "${ISO_BASENAME}" ]]; then
    mv -f "${latest}" "${ISO_PATH}"
  fi
fi

echo "[*] SHA256 → ${ISO_PATH}.sha256"
(
  cd "${ROOT}/out"
  sha256sum "${ISO_BASENAME}" | tee "${ISO_BASENAME}.sha256"
)

mkdir -p "${ROOT}/sourceforge/files"
ln -sfn "${ISO_PATH}" "${ROOT}/sourceforge/files/${ISO_BASENAME}"
cp -f "${ISO_PATH}.sha256" "${ROOT}/sourceforge/files/${ISO_BASENAME}.sha256"

echo "[+] ISO ready: ${ISO_PATH}"
ls -lh "${ISO_PATH}" "${ISO_PATH}.sha256"

if (( DO_UPLOAD )); then
  SF_USER="${SF_USER:-visnudeva}"
  export SF_USER
  export SF_RELEASE="${RELEASE}"
  export ISO_NAME="${ISO_BASENAME}"
  echo "[*] Upload to SourceForge (SF_USER=${SF_USER} SF_RELEASE=${SF_RELEASE})"
  "${ROOT}/sourceforge/upload.sh"
fi

echo "[+] make-iso done."
echo "    Test: dd / Ventoy / qemu from out/${ISO_BASENAME}"
echo "    Upload later: SF_USER=… SF_RELEASE=${RELEASE} ISO_NAME=${ISO_BASENAME} ./sourceforge/upload.sh"
