#!/usr/bin/env bash
# Publish repo/ to the live pacman channel, append an SF changelog entry,
# commit, push (GitHub + SourceForge git), and rsync project web.
#
# Usage (from SweetPotatOs root, as your normal user — not root):
#   ./scripts/ship-stable.sh --en "What changed…" [--fr "Ce qui a changé…"]
#   ./scripts/ship-stable.sh --en "…" --message "Commit subject"
#
# Options:
#   --en TEXT          English changelog HTML (required unless --skip-changelog)
#   --fr TEXT          French changelog HTML (default: same as --en)
#   --message TEXT     git commit message (default: derived from --en)
#   --skip-publish     do not run publish-repo.sh
#   --skip-changelog   do not touch sourceforge/htdocs
#   --skip-commit      do not git add/commit/push
#   --skip-rsync       do not rsync htdocs after push
#   --dry-run          print actions only
#
# Expects packages already built into repo/ (swirl, sweetpotatos, …).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib-spo.sh
source "${ROOT}/scripts/lib-spo.sh"

EN=""
FR=""
MSG=""
DO_PUBLISH=1
DO_CHANGELOG=1
DO_COMMIT=1
DO_RSYNC=1
DRY=0

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --en) EN="${2:-}"; shift 2 ;;
    --fr) FR="${2:-}"; shift 2 ;;
    --message|-m) MSG="${2:-}"; shift 2 ;;
    --skip-publish) DO_PUBLISH=0; shift ;;
    --skip-changelog) DO_CHANGELOG=0; shift ;;
    --skip-commit) DO_COMMIT=0; shift ;;
    --skip-rsync) DO_RSYNC=0; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage 0 ;;
    *) spo_die "Unknown arg: $1 (see --help)" ;;
  esac
done

if (( DO_CHANGELOG )) && [[ -z "${EN}" ]]; then
  spo_die "Pass --en \"changelog text…\" (or --skip-changelog)"
fi
[[ -n "${FR}" ]] || FR="${EN}"
if [[ -z "${MSG}" && -n "${EN}" ]]; then
  MSG="$(python3 -c 'import re,sys; t=re.sub("<[^>]+>","",sys.argv[1]); print(t[:72].rstrip() or "Ship stable channel update.")' "${EN}")"
fi
[[ -n "${MSG}" ]] || MSG="Ship stable channel update."

if [[ "${EUID}" -eq 0 ]]; then
  spo_die "Run as your normal user (not root). publish-repo uses gh as you."
fi

spo_need gh
spo_need git
spo_need rsync
spo_need python3

cd "${ROOT}"

if (( DO_PUBLISH )); then
  shopt -s nullglob
  pkgs=(repo/*.pkg.tar.zst)
  shopt -u nullglob
  ((${#pkgs[@]} > 0)) || spo_die "repo/ has no packages — build first"
  echo "[*] Publish stable (${#pkgs[@]} packages in repo/)"
  if (( DRY )); then
    echo "    dry-run: ./scripts/publish-repo.sh stable"
  else
    ./scripts/publish-repo.sh stable
  fi
fi

if (( DO_CHANGELOG )); then
  N="$(spo_next_fifth "${ROOT}/sourceforge/htdocs/i18n.js")"
  echo "[*] SF changelog → fifth.${N}"
  if (( DRY )); then
    echo "    dry-run: append fifth.${N}"
    echo "    EN: ${EN}"
    echo "    FR: ${FR}"
  else
    spo_changelog_append "${ROOT}" "${N}" "${EN}" "${FR}"
  fi
fi

if (( DO_COMMIT )); then
  echo "[*] git commit + push"
  if (( DRY )); then
    echo "    dry-run: commit -m $(printf %q "${MSG}")"
  else
    # Stage common ship paths; leave junk (wmenu tarball, stages) alone.
    git add -A -- \
      packaging/ \
      profile/airootfs/ \
      sourceforge/htdocs/ \
      scripts/ \
      2>/dev/null || true
    # Unstage accidental blobs if present
    git reset HEAD -- packaging/swirl/wmenu-0.2.0.tar.gz 2>/dev/null || true
    git reset HEAD -- packaging/laniakea/swirl-laniakea 2>/dev/null || true
    git reset HEAD -- .publish-repo-stage .publish-repo-stage-tuber .cheatsheet-snapshots 2>/dev/null || true
    if git diff --cached --quiet; then
      echo "[*] Nothing staged to commit (working tree may already be clean)."
    else
      git commit -m "${MSG}"
    fi
    spo_git_push_all "${ROOT}"
  fi
fi

if (( DO_RSYNC && DO_CHANGELOG )); then
  if (( DRY )); then
    echo "    dry-run: rsync htdocs"
  else
    spo_sf_rsync_htdocs "${ROOT}"
  fi
fi

echo "[+] ship-stable done."
echo "    Installs: sudo sweetpotatos-update"
