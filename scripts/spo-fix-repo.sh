#!/usr/bin/bash
# Recover pacman + install SweetPotatOs overlay when spo-upgrade hits gpgme errors.
# Run:  curl -Lf .../spo-fix-repo.sh | sudo bash -s
set -eo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: curl -Lf .../spo-fix-repo.sh | sudo bash -s" >&2
  exit 1
fi

SPO_REPO_BASE="${SPO_REPO_BASE:-https://downloads.sourceforge.net/project/sweetpotatos/repo/x86_64}"
OVERLAY_PKGS=(sweetpotatos localsend-bin spore swirl yay-bin shelly-bin waypaper)

echo "[1/6] Remove XferCommand (breaks official repo GPG checks)…"
sed -i '/^XferCommand = /d' /etc/pacman.conf

echo "[2/6] Disable overlay repo during official sync…"
[[ -f /etc/pacman.d/sweetpotatos.conf ]] && \
  mv /etc/pacman.d/sweetpotatos.conf /etc/pacman.d/sweetpotatos.conf.off
if grep -q '^\[sweetpotatos\]' /etc/pacman.conf 2>/dev/null; then
  awk '
    /^\[sweetpotatos\]/ { skip=1; next }
    /^\[/ && skip { skip=0 }
    !skip { print }
  ' /etc/pacman.conf > /etc/pacman.conf.spo-fix
  mv /etc/pacman.conf.spo-fix /etc/pacman.conf
fi
sed -i '/Include = \/etc\/pacman.d\/sweetpotatos.conf/d' /etc/pacman.conf

echo "[3/6] Wipe ALL pacman sync databases (fixes gpgme HTML/corrupt .db/.sig)…"
rm -rf /var/lib/pacman/sync/*

echo "[4/6] Prefer a reliable HTTPS mirror…"
if [[ -f /etc/pacman.d/mirrorlist ]]; then
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.spo-fix.bak
  {
    echo '# SweetPotatOs spo-fix: reliable mirrors first'
    echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'
    echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch'
    echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch'
    grep -E '^Server = https:' /etc/pacman.d/mirrorlist.spo-fix.bak || true
  } > /etc/pacman.d/mirrorlist
fi

echo "[5/6] Sync and upgrade official Arch packages…"
if ! pacman -Sy; then
  echo "[!] pacman -Sy failed — check network/DNS, then retry this script" >&2
  exit 1
fi
pacman -Su --noconfirm

echo "[6/6] Install SweetPotatOs overlay packages via curl…"
install -Dm644 /dev/stdin /etc/pacman.d/sweetpotatos.conf <<'EOF'
[sweetpotatos]
SigLevel = Never
Server = https://downloads.sourceforge.net/project/sweetpotatos/repo/x86_64
EOF
grep -qF 'Include = /etc/pacman.d/sweetpotatos.conf' /etc/pacman.conf || \
  printf '\nInclude = /etc/pacman.d/sweetpotatos.conf\n' >> /etc/pacman.conf
rm -f /etc/pacman.d/sweetpotatos.conf.off

work="$(mktemp -d /tmp/spo-fix.XXXXXX)"
trap 'rm -rf "${work}"' EXIT
db="${work}/sweetpotatos.db"
curl -Lf -o "${db}" "${SPO_REPO_BASE}/sweetpotatos.db"
if ! file "${db}" | grep -q 'gzip compressed data'; then
  echo "[!] overlay repo db is not valid: $(file -b "${db}")" >&2
  exit 1
fi

to_install=()
for pkg in "${OVERLAY_PKGS[@]}"; do
  fn="$(tar -xOzf "${db}" --wildcards "${pkg}-*/desc" 2>/dev/null \
    | awk '/^%FILENAME%/{getline; print; exit}')"
  [[ -n "${fn}" ]] || continue
  path="${work}/${fn}"
  echo "    downloading ${fn}…"
  curl -Lf -o "${path}" "${SPO_REPO_BASE}/${fn}"
  to_install+=("${path}")
done

((${#to_install[@]})) || { echo "[!] no overlay packages found" >&2; exit 1; }
# ISO installs ship /usr/local/* in airootfs without pacman — allow overlay to take over.
pacman -U --needed --noconfirm --overwrite '*' "${to_install[@]}"

/usr/local/bin/sweetpotatos-branding 2>/dev/null || true
echo "[+] Done. sweetpotatos package and overlay tools installed."
echo "    Reboot or log out/in, then:  spo-upgrade --check"
