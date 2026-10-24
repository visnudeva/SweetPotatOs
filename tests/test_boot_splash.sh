#!/usr/bin/env bash
# Boot splash stays quiet; must not deadlock waiting on Ly.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assert() { bash -c "$1" || { echo "FAIL: $2" >&2; exit 1; }; echo "[OK] $2"; }

DROP_DIR="${ROOT}/packaging/sweetpotatos/files/usr/lib/systemd/system/plymouth-quit.service.d"
QUIET="${ROOT}/packaging/sweetpotatos/files/usr/local/bin/sweetpotatos-boot-quiet"
GRUBCFG="${ROOT}/profile/airootfs/etc/calamares/modules/grubcfg.conf"
EFI="${ROOT}/profile/efiboot/loader/entries/01-archiso-linux.conf"
INSTALL="${ROOT}/packaging/sweetpotatos/sweetpotatos.install"
PKGBUILD="${ROOT}/packaging/sweetpotatos/PKGBUILD"

chmod +x "${QUIET}"

assert "! [[ -e '${DROP_DIR}' ]]" "broken plymouth-quit drop-in is not shipped"
assert "! grep -q 'plymouth-quit.service.d' '${PKGBUILD}'" "PKGBUILD does not install retain-splash"
assert "grep -q '10-sweetpotatos-retain-splash' '${INSTALL}'" "upgrade removes the deadlocking drop-in"
assert "[[ -x '${QUIET}' ]]" "boot-quiet is executable"
assert "grep -q 'GRUB_DISABLE_OS_PROBER=true' '${QUIET}'" "boot-quiet defaults os-prober off"
assert "grep -q 'loglevel=3' '${GRUBCFG}'" "Calamares GRUB gets quiet loglevel"
assert "grep -q 'systemd.show_status=false' '${GRUBCFG}'" "Calamares GRUB hides systemd status"
assert "grep -q 'loglevel=3' '${EFI}'" "live EFI entry is quiet"
assert "grep -q 'sweetpotatos-boot-quiet' '${INSTALL}'" "upgrade refreshes the quiet cmdline"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/etc/default" "${tmp}/boot/grub"
printf 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n' >"${tmp}/etc/default/grub"
if [[ -f /etc/mkinitcpio.conf.d/archiso.conf ]]; then
  echo "[SKIP] merge test on archiso host"
else
  GRUB_DEFAULT="${tmp}/etc/default/grub" BOOT_GRUB_DIR="${tmp}/boot/grub" \
    PATH="/usr/bin:/bin" bash "${QUIET}"
  got="$(cat "${tmp}/etc/default/grub")"
  assert "[[ '${got}' == *loglevel=3* ]]" "boot-quiet adds loglevel=3"
  assert "[[ '${got}' == *GRUB_DISABLE_OS_PROBER=true* ]]" "boot-quiet disables os-prober by default"
  GRUB_DEFAULT="${tmp}/etc/default/grub" BOOT_GRUB_DIR="${tmp}/boot/grub" \
    PATH="/usr/bin:/bin" bash "${QUIET}"
  got2="$(cat "${tmp}/etc/default/grub")"
  assert "[[ '${got}' == '${got2}' ]]" "boot-quiet is idempotent"
fi

echo "boot splash checks passed"
