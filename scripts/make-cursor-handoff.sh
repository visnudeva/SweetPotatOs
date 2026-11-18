#!/usr/bin/env bash
# Build a portable Cursor handoff archive for continuing SweetPotatOs work
# on another laptop (e.g. holidays on the SPO machine).
#
# Usage (from SweetPotatOs root, normal user):
#   ./scripts/make-cursor-handoff.sh
#   ./scripts/make-cursor-handoff.sh --out ~/Downloads
#   ./scripts/make-cursor-handoff.sh --open   # print path + list contents
#
# Writes:
#   <out>/sweetpotatos-cursor-handoff-YYYY-MM-DD.zip
#   <out>/sweetpotatos-cursor-handoff-YYYY-MM-DD.tar.gz
#   (and a matching unpacked folder next to them)
#
# Does NOT include SSH private keys — copy those separately.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib-spo.sh
source "${ROOT}/scripts/lib-spo.sh"

OUT_DIR="${HOME}/Downloads"
OPEN=0
DATE="$(date +%Y-%m-%d)"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --date) DATE="${2:-}"; shift 2 ;;
    --open) OPEN=1; shift ;;
    -h|--help) usage 0 ;;
    *) spo_die "Unknown arg: $1 (see --help)" ;;
  esac
done

[[ -n "${OUT_DIR}" ]] || spo_die "--out needs a directory"
mkdir -p "${OUT_DIR}"
OUT_DIR="$(cd "${OUT_DIR}" && pwd)"

NAME="sweetpotatos-cursor-handoff-${DATE}"
STAGE="${OUT_DIR}/${NAME}"
rm -rf "${STAGE}"
mkdir -p "${STAGE}/docs" "${STAGE}/cursor-rules" "${STAGE}/rashin-memory"

spo_need python3

# --- copy static docs -------------------------------------------------------
[[ -f "${ROOT}/NOTES.md" ]] || spo_die "Missing NOTES.md"
[[ -f "${ROOT}/AGENT_MEMORY_BACKUP.md" ]] || spo_die "Missing AGENT_MEMORY_BACKUP.md"
cp -a "${ROOT}/NOTES.md" "${STAGE}/docs/"
cp -a "${ROOT}/AGENT_MEMORY_BACKUP.md" "${STAGE}/docs/"

RULES="${ROOT}/.cursor/rules/project-notes.mdc"
if [[ -f "${RULES}" ]]; then
  cp -a "${RULES}" "${STAGE}/cursor-rules/"
else
  echo "[!] No .cursor/rules/project-notes.mdc — continuing without it" >&2
fi

RASHIN_MEM="${HOME}/.local/share/ryoku/rashin/memory"
if [[ -d "${RASHIN_MEM}" ]]; then
  for f in sweetpotato-branding-bleed.md sweetpotatos-pacman-leftover.md; do
    [[ -f "${RASHIN_MEM}/${f}" ]] && cp -a "${RASHIN_MEM}/${f}" "${STAGE}/rashin-memory/"
  done
fi

# --- detect sibling repos / versions ----------------------------------------
POTATO_DIR="${SWEETPOTATO_DIR:-$(cd "${ROOT}/../SweetPotato" 2>/dev/null && pwd || true)}"
TUBER_DIR=""
for cand in "${ROOT}/../tuber" "${ROOT}/../../tuber" "${HOME}/code/tuber"; do
  if [[ -d "${cand}/.git" ]]; then
    TUBER_DIR="$(cd "${cand}" && pwd)"
    break
  fi
done

repo_ver() {
  local name="$1" f
  shopt -s nullglob
  local files=( "${ROOT}/repo/${name}"-[0-9]*.pkg.tar.* )
  shopt -u nullglob
  ((${#files[@]})) || { echo "(not in repo/)"; return; }
  # newest by version sort of basename
  f="$(printf '%s\n' "${files[@]}" | sed 's|.*/||;s/\.pkg\.tar\..*$//' | grep -v -- '-debug-' | sort -V | tail -1)"
  printf '%s\n' "${f#"${name}-"}"
}

SPO_HEAD="$(git -C "${ROOT}" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)"
SPO_LOG="$(git -C "${ROOT}" log -8 --oneline 2>/dev/null || true)"
POTATO_HEAD="(missing)"
POTATO_LOG=""
if [[ -n "${POTATO_DIR}" && -d "${POTATO_DIR}/.git" ]]; then
  POTATO_HEAD="$(git -C "${POTATO_DIR}" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)"
  POTATO_LOG="$(git -C "${POTATO_DIR}" log -5 --oneline 2>/dev/null || true)"
fi
TUBER_HEAD="(missing)"
if [[ -n "${TUBER_DIR}" ]]; then
  TUBER_HEAD="$(git -C "${TUBER_DIR}" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)"
fi

VER_SWEET="$(repo_ver sweetpotatos)"
VER_SWIRL="$(repo_ver swirl)"
VER_TUBER="$(repo_ver tuber)"
VER_SPORE="$(repo_ver spore)"
VER_LANI="$(repo_ver laniakea)"
VER_BRAVE="$(repo_ver brave-origin-bin)"
VER_SHELLY="$(repo_ver shelly-bin)"
VER_LOCAL="$(repo_ver localsend-bin)"
VER_WAY="$(repo_ver waypaper)"
VER_YAY="$(repo_ver yay-bin)"
VER_LOCK="$(repo_ver swaylock-effects)"

HOST="$(hostname 2>/dev/null || echo unknown)"
USER_NAME="$(id -un 2>/dev/null || echo visnudeva)"

# --- PASTE-TO-CURSOR.md -----------------------------------------------------
cat > "${STAGE}/PASTE-TO-CURSOR.md" <<EOF
# Paste this into Cursor

Continuing SweetPotatOs with me (${USER_NAME}). Bootstrap already ran.

Read these from the handoff folder next to the repo (or ask me for the path):
\`RESUME.md\`, then \`docs/NOTES.md\` / \`docs/AGENT_MEMORY_BACKUP.md\` as needed.

Rules: theme edits in **SweetPotato** + \`./sync-theme.sh\`; publish to **testing** until I say stable; push SweetPotatOs to GitHub **and** SourceForge when shipping git.

Say when you’ve read RESUME.md and are ready.
EOF

# --- bootstrap-on-spo.sh (run on the SPO laptop) ----------------------------
cat > "${STAGE}/bootstrap-on-spo.sh" <<'BOOT'
#!/usr/bin/env bash
# One-shot setup on the SweetPotatOs laptop. Run from inside this unzipped folder:
#   ./bootstrap-on-spo.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="${HOME}/code/GITHUB"
SPO="${BASE}/SweetPotatOs"
POTATO="${BASE}/SweetPotato"

mkdir -p "${BASE}"

if [[ ! -d "${SPO}/.git" ]]; then
  echo "[*] Cloning SweetPotatOs…"
  git clone https://github.com/visnudeva/SweetPotatOs.git "${SPO}"
else
  echo "[*] SweetPotatOs already cloned — pulling"
  git -C "${SPO}" pull --ff-only || true
fi

if [[ ! -d "${POTATO}/.git" ]]; then
  echo "[*] Cloning SweetPotato…"
  git clone https://github.com/visnudeva/SweetPotato.git "${POTATO}"
else
  echo "[*] SweetPotato already cloned — pulling"
  git -C "${POTATO}" pull --ff-only || true
fi

if ! git -C "${SPO}" remote get-url sourceforge >/dev/null 2>&1; then
  git -C "${SPO}" remote add sourceforge ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code
  echo "[*] Added sourceforge remote"
fi

mkdir -p "${SPO}/.cursor/rules"
if [[ -f "${HERE}/cursor-rules/project-notes.mdc" ]]; then
  cp -a "${HERE}/cursor-rules/project-notes.mdc" "${SPO}/.cursor/rules/"
  echo "[*] Installed Cursor project rules"
fi

# Keep a copy of this handoff next to the repo for the agent.
LINK="${SPO}/.cursor-handoff"
rm -rf "${LINK}"
cp -a "${HERE}" "${LINK}"
echo "[*] Handoff copied to ${LINK}"

echo
echo "Done. Next:"
echo "  1. Open ${SPO} in Cursor"
echo "  2. Paste PASTE-TO-CURSOR.md into chat"
echo "     (also at ${LINK}/PASTE-TO-CURSOR.md)"
if [[ ! -f "${HOME}/.ssh/id_ed25519_sourceforge" ]]; then
  echo
  echo "Note: put id_ed25519_sourceforge in ~/.ssh if you need SourceForge push/rsync."
fi
BOOT
chmod +x "${STAGE}/bootstrap-on-spo.sh"

# --- START-HERE.txt (only instructions humans need) -------------------------
cat > "${STAGE}/START-HERE.txt" <<EOF
On the SweetPotatOs PC — 3 steps
================================

1. Unzip this folder.
2. In a terminal inside it:
     ./bootstrap-on-spo.sh
3. Open ~/code/GITHUB/SweetPotatOs in Cursor and paste PASTE-TO-CURSOR.md

Optional: copy your SourceForge SSH key to ~/.ssh if you will publish.
Optional: sudo sweetpotatos-update

Built on ${HOST} (${DATE}).
EOF

# Keep CHECKLIST as a pointer only
cat > "${STAGE}/CHECKLIST.txt" <<EOF
See START-HERE.txt — that is the whole SPO-laptop flow.
EOF
# --- RESUME.md (generated) --------------------------------------------------
cat > "${STAGE}/RESUME.md" <<EOF
# SweetPotatOs — Cursor handoff (${DATE})

Generated on **${HOST}** by \`./scripts/make-cursor-handoff.sh\` so work can continue on another laptop.

## Two laptops / Cursor

- Same Cursor account works on **both** machines. Using one does **not** disconnect the other.
- Chat / agent transcripts stay **local** unless you copy them. This archive is the portable memory.
- Source of truth for code is GitHub / SourceForge — pull on the destination laptop.

## Git tips (when this was built)

| Repo | HEAD |
|------|------|
| SweetPotatOs | \`${SPO_HEAD}\` |
| SweetPotato | \`${POTATO_HEAD}\` |
| tuber | \`${TUBER_HEAD}\` |

### SweetPotatOs recent commits

\`\`\`
${SPO_LOG:-"(none)"}
\`\`\`

### SweetPotato recent commits

\`\`\`
${POTATO_LOG:-"(none / sibling missing)"}
\`\`\`

## Channel packages (from local \`repo/\`)

Newest non-debug package per name in \`${ROOT}/repo\`:

| Package | Version |
|---------|---------|
| sweetpotatos | ${VER_SWEET} |
| swirl | ${VER_SWIRL} |
| tuber | ${VER_TUBER} |
| spore | ${VER_SPORE} |
| laniakea | ${VER_LANI} |
| brave-origin-bin | ${VER_BRAVE} |
| shelly-bin | ${VER_SHELLY} |
| localsend-bin | ${VER_LOCAL} |
| waypaper | ${VER_WAY} |
| yay-bin | ${VER_YAY} |
| swaylock-effects | ${VER_LOCK} |

Stable tag: \`pacman-repo\`. Testing tag: \`pacman-repo-testing\`. Promote only when asked.

## Maintainer commands

\`\`\`bash
./scripts/bump-channel-apps.sh --publish-testing
./scripts/ship-stable.sh --en "…" --fr "…"
./scripts/make-iso.sh --fifth
./scripts/make-cursor-handoff.sh
\`\`\`

## On the SPO laptop

Read \`START-HERE.txt\` — unzip, run \`./bootstrap-on-spo.sh\`, paste into Cursor.

## Do not commit

\`.cheatsheet-snapshots/\`, \`.publish-repo-stage*\`, \`packaging/laniakea/swirl-laniakea/\`, \`packaging/swirl/wmenu-0.2.0.tar.gz\`, \`__pycache__\`.
EOF

cp -a "${STAGE}/START-HERE.txt" "${STAGE}/README.txt"
# --- archives ---------------------------------------------------------------
ZIP="${OUT_DIR}/${NAME}.zip"
TAR="${OUT_DIR}/${NAME}.tar.gz"
rm -f "${ZIP}" "${TAR}"

(
  cd "${OUT_DIR}"
  tar -czf "${NAME}.tar.gz" "${NAME}"
)

python3 - "${OUT_DIR}" "${NAME}" <<'PY'
import sys, zipfile
from pathlib import Path
out, name = Path(sys.argv[1]), sys.argv[2]
root = out / name
zpath = out / f"{name}.zip"
with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
    for p in root.rglob("*"):
        if p.is_file():
            z.write(p, p.relative_to(out))
print(zpath)
PY

echo "[+] Handoff ready:"
echo "    folder: ${STAGE}"
echo "    zip:    ${ZIP} ($(du -h "${ZIP}" | awk '{print $1}'))"
echo "    tar:    ${TAR} ($(du -h "${TAR}" | awk '{print $1}'))"
echo "    Email/USB the zip; keep SSH keys off email."

if (( OPEN )); then
  echo "[*] Contents:"
  find "${STAGE}" -type f | sed "s|^${STAGE}/|    |" | sort
fi
