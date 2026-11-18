# Shared helpers for SweetPotatOs ship/bump/iso scripts.
# shellcheck shell=bash

spo_root() {
  cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd
}

spo_die() {
  echo "[!] $*" >&2
  exit 1
}

spo_need() {
  command -v "$1" >/dev/null 2>&1 || spo_die "Need $1 on PATH"
}

# Next changelog.fifth.N (max existing + 1).
spo_next_fifth() {
  local i18n="$1"
  local n
  n="$(grep -oE 'changelog\.fifth\.[0-9]+' "${i18n}" | grep -oE '[0-9]+$' | sort -n | tail -1)"
  [[ -n "${n}" ]] || n=0
  echo $((n + 1))
}

# Escape a string for use inside a double-quoted JS JSON string value.
spo_js_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1])[1:-1])' "$1"
}

# Insert a new fifth.N entry at the top of the Fifth Harvest list (EN + FR + HTML).
# Args: root, N, en_html, fr_html
spo_changelog_append() {
  local root="$1" n="$2" en="$3" fr="$4"
  local i18n="${root}/sourceforge/htdocs/i18n.js"
  local html="${root}/sourceforge/htdocs/changelog.html"
  local en_esc fr_esc prev

  [[ -f "${i18n}" && -f "${html}" ]] || spo_die "Missing changelog files under sourceforge/htdocs/"
  grep -q "changelog.fifth.${n}" "${i18n}" && spo_die "changelog.fifth.${n} already exists"

  en_esc="$(spo_js_escape "${en}")"
  fr_esc="$(spo_js_escape "${fr}")"
  prev=$((n - 1))
  while ((prev > 0)) && ! grep -q "\"changelog.fifth.${prev}\"" "${i18n}"; do
    prev=$((prev - 1))
  done
  ((prev > 0)) || spo_die "Could not find a previous changelog.fifth.* anchor in i18n.js"

  python3 - "${i18n}" "${html}" "${n}" "${prev}" "${en_esc}" "${fr_esc}" "${en}" <<'PY'
import pathlib, sys
i18n_path, html_path, n, prev, en_esc, fr_esc, en_html = sys.argv[1:8]
i18n = pathlib.Path(i18n_path).read_text()
html = pathlib.Path(html_path).read_text()

en_line = f'      "changelog.fifth.{n}": "{en_esc}",\n'
fr_line = f'      "changelog.fifth.{n}": "{fr_esc}",\n'
anchor = f'"changelog.fifth.{prev}":'

# First occurrence = English block, second = French.
idxs = []
start = 0
while True:
    i = i18n.find(anchor, start)
    if i < 0:
        break
    idxs.append(i)
    start = i + 1
if len(idxs) < 2:
    raise SystemExit(f"Need EN+FR anchors for changelog.fifth.{prev}, found {len(idxs)}")

# Insert before each anchor (FR first from the end so offsets stay valid).
for i, line in ((idxs[1], fr_line), (idxs[0], en_line)):
    i18n = i18n[:i] + line + "      " + i18n[i:]

needle = f'<li data-i18n-html="changelog.fifth.{prev}">'
if needle not in html:
    raise SystemExit(f"Missing HTML anchor for fifth.{prev}")
li = (
    f'<li data-i18n-html="changelog.fifth.{n}">{en_html}</li>\n'
    f'        {needle}'
)
html = html.replace(needle, li, 1)

pathlib.Path(i18n_path).write_text(i18n)
pathlib.Path(html_path).write_text(html)
print(f"[+] changelog.fifth.{n} added (EN/FR + HTML)")
PY
}

spo_sf_rsync_htdocs() {
  local root="$1"
  local user="${SF_USER:-visnudeva}"
  local key="${SF_SSH_KEY:-${HOME}/.ssh/id_ed25519_sourceforge}"
  local ssh=(ssh -o IdentitiesOnly=yes)
  [[ -f "${key}" ]] && ssh+=(-i "${key}")
  echo "[*] rsync htdocs → SourceForge web (${user})"
  rsync -avP -e "${ssh[*]}" \
    "${root}/sourceforge/htdocs/" \
    "${user}@web.sourceforge.net:/home/project-web/sweetpotatos/htdocs/"
}

spo_git_push_all() {
  local root="$1"
  (
    cd "${root}"
    git push origin HEAD
    if git remote get-url sourceforge >/dev/null 2>&1; then
      git push sourceforge HEAD || echo "[!] sourceforge git push failed (web rsync may still work)" >&2
    fi
  )
}

spo_bump_pkgrel() {
  local pkgbuild="$1"
  local cur next
  cur="$(grep -E '^pkgrel=' "${pkgbuild}" | head -1 | cut -d= -f2)"
  [[ -n "${cur}" ]] || spo_die "No pkgrel= in ${pkgbuild}"
  next=$((cur + 1))
  sed -i "s/^pkgrel=${cur}$/pkgrel=${next}/" "${pkgbuild}"
  echo "${next}"
}

spo_sweetpotatos_news() {
  local root="$1"
  local rel="$2"
  local note="$3"
  local news="${root}/packaging/sweetpotatos/update-news"
  local block
  block="$(printf '@%s\n%s\n\n' "${rel}" "${note}")"
  if grep -q "^@${rel}$" "${news}"; then
    spo_die "update-news already has @${rel}"
  fi
  python3 - "${news}" "${block}" <<'PY'
from pathlib import Path
import re, sys
path, block = Path(sys.argv[1]), sys.argv[2]
text = path.read_text()
text2 = re.sub(r'(@2026\.10\.3-\d+\n)', block + r'\1', text, count=1)
if text2 == text:
    # No versioned block yet — insert after the header comments.
    parts = text.split('\n\n', 1)
    text2 = parts[0] + '\n\n' + block + (parts[1] if len(parts) > 1 else '')
path.write_text(text2)
print(f"[+] update-news @{block.splitlines()[0][1:]}")
PY
}

spo_pkgbuild_get() {
  local pkgbuild="$1" key="$2"
  grep -E "^${key}=" "${pkgbuild}" | head -1 | cut -d= -f2- | tr -d "'\""
}

# Full SHA of the tip of a GitHub repo branch (default main).
spo_gh_latest_commit() {
  local repo="$1"
  local branch="${2:-main}"
  gh api "repos/${repo}/commits/${branch}" --jq '.sha'
}

# Latest GitHub release tag (no leading v). Optional: filter asset name substring.
spo_gh_latest_tag() {
  local repo="$1"
  local asset_substr="${2:-}"
  if [[ -n "${asset_substr}" ]]; then
    gh api "repos/${repo}/releases?per_page=40" \
      | python3 -c 'import json,sys
s=sys.argv[1]
for r in json.load(sys.stdin):
  if r.get("draft") or r.get("prerelease"): continue
  names=[a.get("name") or "" for a in (r.get("assets") or [])]
  if any(s in n for n in names):
    print((r.get("tag_name") or "").lstrip("v")); break
' "${asset_substr}"
  else
    gh api "repos/${repo}/releases/latest" --jq '.tag_name' | sed 's/^v//'
  fi
}

# AUR package Version (pkgver only, strip pkgrel / epoch).
spo_aur_pkgver() {
  local name="$1"
  curl -fsSL "https://aur.archlinux.org/rpc/v5/info?arg[]=${name}" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); r=d.get("results") or [];
print((r[0]["Version"].split(":")[-1].rsplit("-",1)[0]) if r else "")'
}

# Set pkgver= and pkgrel=1 in a PKGBUILD; leave sha256 for caller.
spo_pkgbuild_set_pkgver() {
  local pkgbuild="$1" ver="$2"
  sed -i -E "s/^pkgver=.*/pkgver=${ver}/" "${pkgbuild}"
  sed -i -E "s/^pkgrel=.*/pkgrel=1/" "${pkgbuild}"
}

# Refresh sha256sums* in PKGBUILD via makepkg -g (needs network).
spo_pkgbuild_regen_sums() {
  local dir="$1"
  (
    cd "${dir}"
    # Drop old sums so -g rewrites them cleanly.
    sed -i -E '/^sha256sums(_[a-z0-9]+)?=/,/^\)/d' PKGBUILD
    local sums
    sums="$(makepkg -g 2>/dev/null)"
    [[ -n "${sums}" ]] || spo_die "makepkg -g failed in ${dir}"
    # Insert after the last source*_=) block (or after noextract=).
    python3 - "${sums}" <<'PY'
from pathlib import Path
import sys
sums = sys.argv[1].rstrip() + "\n"
text = Path("PKGBUILD").read_text()
# Place sums after noextract=... or after last source*_ block closing ).
import re
m = list(re.finditer(r'^(?:noextract|source(?:_[a-z0-9]+)?)=.*?(?:\)\n)', text, re.M | re.S))
if not m:
    raise SystemExit("no source=/noextract= block to anchor sums")
i = m[-1].end()
Path("PKGBUILD").write_text(text[:i] + sums + text[i:])
print("[+] regenerated sha256sums")
PY
  )
}

# Build a packaging/<name> local PKGBUILD into repo/ (normal user; no sudo).
spo_makepkg_local() {
  local root="$1" name="$2"
  local src="${root}/packaging/${name}"
  local build="${root}/.aur-build/${name}"
  local repo="${root}/repo"
  [[ -f "${src}/PKGBUILD" ]] || spo_die "Missing ${src}/PKGBUILD"
  mkdir -p "${root}/.aur-build" "${repo}"
  rm -rf "${build}"
  mkdir -p "${build}"
  cp -a "${src}/." "${build}/"
  (
    cd "${build}"
    makepkg -sf --noconfirm
  )
  shopt -s nullglob
  local built=( "${build}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#built[@]} > 0)) || spo_die "makepkg produced nothing for ${name}"
  # Drop older same-name packages from repo/
  rm -f "${repo}/${name}"-*.pkg.tar.* "${repo}/${name}"-*-debug-*.pkg.tar.* 2>/dev/null || true
  cp -a "${built[@]}" "${repo}/"
  echo "[+] ${name} → repo/"
}

# Build an AUR package into repo/ (clone/pull + makepkg).
spo_makepkg_aur() {
  local root="$1" name="$2" url="$3"
  local build="${root}/.aur-build/${name}"
  local repo="${root}/repo"
  mkdir -p "${root}/.aur-build" "${repo}"
  if [[ ! -d "${build}/.git" ]]; then
    rm -rf "${build}"
    git clone --depth 1 "${url}" "${build}"
  else
    git -C "${build}" pull --ff-only || true
  fi
  (
    cd "${build}"
    makepkg -sf --noconfirm
  )
  shopt -s nullglob
  local built=( "${build}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#built[@]} > 0)) || spo_die "makepkg produced nothing for ${name}"
  rm -f "${repo}/${name}"-*.pkg.tar.* 2>/dev/null || true
  cp -a "${built[@]}" "${repo}/"
  echo "[+] ${name} → repo/"
}

spo_repo_add_refresh() {
  local root="$1"
  local repo="${root}/repo"
  spo_need repo-add
  rm -f "${repo}/sweetpotatos.db.tar.gz" "${repo}/sweetpotatos.db" \
        "${repo}/sweetpotatos.files.tar.gz" "${repo}/sweetpotatos.files"
  shopt -s nullglob
  local pkgs=( "${repo}"/*.pkg.tar.* )
  shopt -u nullglob
  ((${#pkgs[@]} > 0)) || spo_die "repo/ empty"
  repo-add "${repo}/sweetpotatos.db.tar.gz" "${pkgs[@]}"
}

spo_sweetpotatos_ver() {
  local pb="$1"
  echo "$(spo_pkgbuild_get "${pb}" pkgver)-$(spo_pkgbuild_get "${pb}" pkgrel)"
}

# Apply Fifth/Fourth harvest naming into profiledef.sh + env for build.sh.
# Args: root, release_folder (e.g. 2026.12_Fifth_Harvest), label, application
spo_set_iso_identity() {
  local root="$1" version="$2" label="$3" application="$4"
  local pf="${root}/profile/profiledef.sh"
  sed -i -E "s|^iso_label=.*|iso_label=\"${label}\"|" "${pf}"
  sed -i -E "s|^iso_application=.*|iso_application=\"${application}\"|" "${pf}"
  sed -i -E "s|^iso_version=.*|iso_version=\"${version}\"|" "${pf}"
  echo "[+] profiledef: ${version} / ${label}"
}
