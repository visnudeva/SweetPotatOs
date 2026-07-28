#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="sweetpotatoos"
iso_label="SPOTATO_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="SweetPotatOs"
iso_application="SweetPotatOs Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
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
  ["/usr/local/bin/sweetpotatoos-session"]="0:0:755"
  ["/home/liveuser"]="1000:1000:755"
  ["/etc/sudoers.d/liveuser"]="0:0:440"
  ["/home/liveuser/.config/sway/scripts/applauncher.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/apply-theme.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/brightness.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/media.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/status.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/volume.sh"]="1000:1000:755"
  ["/home/liveuser/.config/sway/scripts/wallpaper.sh"]="1000:1000:755"
  ["/home/liveuser/.local/bin/sway"]="1000:1000:755"
  ["/etc/skel/.config/sway/scripts/applauncher.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/apply-theme.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/brightness.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/media.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/status.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/volume.sh"]="0:0:755"
  ["/etc/skel/.config/sway/scripts/wallpaper.sh"]="0:0:755"
  ["/etc/skel/.local/bin/sway"]="0:0:755"
)
