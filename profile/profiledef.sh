#!/usr/bin/env bash
# shellcheck disable=SC2034
# articOs profiledef.sh — derived from Archcraft
# Kernel: linux-zen | Security: AppArmor + Firejail | Profiles: artic-profile

iso_name="articOs"
iso_label="ARTICOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="articOs Project <https://github.com/articOs/articOs>"
iso_application="articOs — Adaptive Linux. Minimal by default, powerful on demand."
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:0400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/artic-profile"]="0:0:755"
  ["/usr/local/bin/artic-snapshot"]="0:0:755"
  ["/usr/local/bin/artic-box"]="0:0:755"
  ["/usr/local/bin/artic-install"]="0:0:755"
  ["/usr/local/bin/artic-secure"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/xflock4"]="0:0:755"
)
