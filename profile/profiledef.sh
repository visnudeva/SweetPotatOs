#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="Sweetpotatos"
iso_label="SPOTATO_FOURTH202610"
iso_publisher="SweetPotatOs"
iso_application="SweetPotatOs 2026.10 Fourth Harvest"
iso_version="2026.10_Fourth_Harvest"
install_dir="spotato"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/sweetpotatos-calamares"]="0:0:755"
  ["/usr/local/bin/sweetpotatos-cleanup-live"]="0:0:755"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
  ["/usr/local/bin/sweetpotatos-sway-xkb-sync"]="0:0:755"
  ["/usr/local/bin/sweetpotatos-sway-xkb-watch"]="0:0:755"
  ["/home/liveuser"]="1000:1000:755"
  ["/etc/sudoers.d/liveuser"]="0:0:440"
  # Trailing slash: mkarchiso chmod -R. A named list dropped newer scripts
  # (theme, frame, workspace-dots) and the live session never ran them.
  ["/home/liveuser/.config/swirl/scripts/"]="1000:1000:755"
  ["/home/liveuser/.local/bin/"]="1000:1000:755"
  ["/etc/skel/.config/swirl/scripts/"]="0:0:755"
  ["/etc/skel/.local/bin/"]="0:0:755"
)
