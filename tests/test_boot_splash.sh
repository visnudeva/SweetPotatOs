#!/usr/bin/env bash
# Boot splash stays quiet and retains the logo until Ly.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert() { bash -c "$1" || { echo "FAIL: $2" >&2; exit 1; }; echo "[OK] $2"; }

DROP="${ROOT}/packaging/sweetpotatos/files/usr/lib/systemd/system/plymouth-quit.service.d/10-sweetpotatos-retain-splash.conf"
QUIET="${ROOT}/packaging/sweetpotatos/files/usr/local/bin/sweetpotatos-boot-quiet"
GRUBCFG="${ROOT}/profile/airootfs/etc/calamares/modules/grubcfg.conf"
EFI="${ROOT}/profile/efiboot/loader/entries/01-archiso-linux.conf"

chmod +x "${QUIET}"

assert "[[ -f '${DROP}' ]]" "retain-splash drop-in exists"
assert "grep -q 'retain-splash' '${DROP}'" "plymouth-quit uses --retain-splash"
assert "grep -q 'ly@tty2' '${DROP}'" "splash waits for Ly"
assert "[[ -x '${QUIET}' ]]" "boot-quiet is executable"
assert "grep -q 'loglevel=3' '${GRUBCFG}'" "Calamares GRUB gets quiet loglevel"
assert "grep -q 'systemd.show_status=false' '${GRUBCFG}'" "Calamares GRUB hides systemd status"
assert "grep -q 'loglevel=3' '${EFI}'" "live EFI entry is quiet"
assert "grep -q 'sweetpotatos-boot-quiet' '${ROOT}/packaging/sweetpotatos/sweetpotatos.install'" \
  "upgrade refreshes the quiet cmdline"
assert "grep -q 'sweetpotatos-boot-quiet' '${ROOT}/packaging/sweetpotatos/PKGBUILD'" \
  "package ships boot-quiet"
assert "grep -q 'plymouth-quit.service.d' '${ROOT}/packaging/sweetpotatos/PKGBUILD'" \
  "package ships the retain-splash drop-in"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/etc/default" "${tmp}/boot/grub"
printf 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n' >"${tmp}/etc/default/grub"
# Avoid the live-ISO early exit if this host happens to have archiso.conf.
if [[ -f /etc/mkinitcpio.conf.d/archiso.conf ]]; then
  echo "[SKIP] merge test on archiso host"
else
  GRUB_DEFAULT="${tmp}/etc/default/grub" BOOT_GRUB_DIR="${tmp}/boot/grub" \
    PATH="/usr/bin:/bin" bash "${QUIET}"
  got="$(grep GRUB_CMDLINE_LINUX_DEFAULT= "${tmp}/etc/default/grub")"
  assert "[[ '${got}' == *loglevel=3* ]]" "boot-quiet adds loglevel=3"
  assert "[[ '${got}' == *systemd.show_status=false* ]]" "boot-quiet adds systemd.show_status=false"
  GRUB_DEFAULT="${tmp}/etc/default/grub" BOOT_GRUB_DIR="${tmp}/boot/grub" \
    PATH="/usr/bin:/bin" bash "${QUIET}"
  got2="$(grep GRUB_CMDLINE_LINUX_DEFAULT= "${tmp}/etc/default/grub")"
  assert "[[ '${got}' == '${got2}' ]]" "boot-quiet is idempotent"
fi

echo "boot splash checks passed"
