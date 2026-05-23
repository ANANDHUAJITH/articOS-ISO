#!/usr/bin/env bash
## articOs customize_airootfs.sh
## Runs inside the chroot during ISO build to finalize the live environment.
set -e -u

## ── Kernel: switch from linux → linux-zen ────────────────────────────────────
sed -i 's/vmlinuz-linux\b/vmlinuz-linux-zen/g' /etc/mkinitcpio.d/*.preset 2>/dev/null || true

## Update mkinitcpio for linux-zen + plymouth + zstd
sed -i '/etc/mkinitcpio.conf' \
    -e "s/microcode/microcode plymouth/g" \
    -e "s/#COMPRESSION=.*/COMPRESSION=\"zstd\"/g"

## Write linux-zen preset
cat > "/etc/mkinitcpio.d/linux-zen.preset" << '_EOF_'
ALL_kver="/boot/vmlinuz-linux-zen"
ALL_config="/etc/mkinitcpio.conf"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux-zen.img"
fallback_image="/boot/initramfs-linux-zen-fallback.img"
fallback_options="-S autodetect"
_EOF_

rm -rf /etc/mkinitcpio.conf.d
rm -rf /etc/mkinitcpio.d/linux.preset
rm -rf /etc/mkinitcpio.d/linux-nvidia.preset

## ── Pacman: parallel downloads ───────────────────────────────────────────────
sed -i -e 's|#ParallelDownloads.*|ParallelDownloads = 10|g' /etc/pacman.conf
# Truncate at any testing/custom repo noise left by the build environment
sed -i -e '/#\[core-testing\]/Q' /etc/pacman.conf
# Write clean articOS repo config (no archcraft dependency)
cat >> "/etc/pacman.conf" << 'EOL'

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOL

## ── Hostname / Identity ──────────────────────────────────────────────────────
echo "articOs" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost
::1         localhost
127.0.1.1   articOs.localdomain articOs
HOSTS

## ── Shell defaults ───────────────────────────────────────────────────────────
sed -i -e 's#SHELL=.*#SHELL=/bin/zsh#g' /etc/default/useradd

## ── Security: AppArmor on boot ───────────────────────────────────────────────
sed -i -e 's/vt.global_cursor_default=0/vt.global_cursor_default=0 lsm=landlock,lockdown,yama,integrity,apparmor,bpf/g' \
    /etc/default/grub 2>/dev/null || true

## ── Security: kernel hardening sysctl ───────────────────────────────────────
cat > /etc/sysctl.d/99-artic-harden.conf << 'SYSCTL'
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.randomize_va_space = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0
vm.swappiness = 10
SYSCTL

## ── Install artic tools to /usr/local/bin ────────────────────────────────────
for tool in artic-profile artic-snapshot artic-box artic-secure artic-install; do
    if [[ -f "/usr/local/bin/${tool}" ]]; then
        chmod +x "/usr/local/bin/${tool}"
    fi
done

## ── Profile system: install system-wide profiles ─────────────────────────────
mkdir -p /etc/artic/profiles /etc/artic/hooks
if [[ -d /root/artic-profiles/profiles ]]; then
    cp /root/artic-profiles/profiles/*.conf /etc/artic/profiles/
fi
echo "none" > /etc/artic/active_profile
chmod 644 /etc/artic/profiles/*.conf 2>/dev/null || true

## ── zshrc: source artic profile env ─────────────────────────────────────────
cat >> /etc/skel/.zshrc << 'ZSHRC'

## articOs — source active profile environment
[[ -f ~/.config/artic/profile.env ]] && source ~/.config/artic/profile.env

## articOs aliases
alias artic-help='artic-profile --help'
alias snap='artic-snapshot'
alias box='artic-box'
ZSHRC

## ── Flatpak: add flathub remote ──────────────────────────────────────────────
if command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo || true
fi

## ── btrfs auto-snapshot: enable snapper if btrfs root ───────────────────────
cat > /etc/systemd/system/artic-snapshot-setup.service << 'SNAPUNIT'
[Unit]
Description=articOs — Set up snapshots on first boot
After=local-fs.target
ConditionPathExists=!/etc/artic/.snapshots-configured

[Service]
Type=oneshot
ExecStart=/usr/local/bin/artic-snapshot setup
ExecStartPost=/bin/bash -c 'touch /etc/artic/.snapshots-configured'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SNAPUNIT
systemctl enable artic-snapshot-setup.service 2>/dev/null || true

## ── Copy configs into root home ───────────────────────────────────────────────
rdir="/root/.config"
sdir="/etc/skel"
[[ -d "$rdir" ]] || mkdir "$rdir"

rconfig=(geany gtk-3.0 Kvantum fastfetch qt5ct qt6ct ranger Thunar xfce4)
for cfg in "${rconfig[@]}"; do
    [[ -e "$sdir/.config/$cfg" ]] && cp -rf "$sdir/.config/$cfg" "$rdir"
done

rcfg=('.gtkrc-2.0' '.oh-my-zsh' '.vim_runtime' '.vimrc' '.zshrc')
for cfile in "${rcfg[@]}"; do
    [[ -e "$sdir/$cfile" ]] && cp -rf "$sdir/$cfile" /root
done

## ── articOs MOTD ─────────────────────────────────────────────────────────────
cat > /etc/motd << 'MOTD'

   ██████╗  ██████╗████████╗██╗ ██████╗ ██████╗ ███████╗
  ██╔═══██╗██╔════╝╚══██╔══╝██║██╔════╝██╔═══██╗██╔════╝
  ███████║█████╗     ██║   ██║██║     ██║   ██║███████╗
  ██╔══██║██╔══╝     ██║   ██║██║     ██║   ██║╚════██║
  ██║  ██║╚██████╗   ██║   ██║╚██████╗╚██████╔╝███████║
  ╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
  Adaptive Linux • Minimal base • Your shape, your rules
  ─────────────────────────────────────────────────────────
  artic-profile    Select a productivity profile (Super+P)
  artic-snapshot   Manage system snapshots
  artic-box        Container & isolated environments
  artic-secure     Security hardening & audit
  ─────────────────────────────────────────────────────────

MOTD

## ── Welcome app: launch artic-profile on first login ─────────────────────────
# Create skeleton openbox config dir — may not exist if openbox is freshly installed
mkdir -p /etc/skel/.config/openbox
# Seed a minimal autostart if none exists yet
[[ -f /etc/skel/.config/openbox/autostart ]] || touch /etc/skel/.config/openbox/autostart
sed -i -e '/## articOs-Welcome-Run-Once/Q' /etc/skel/.config/openbox/autostart
cat >> "/etc/skel/.config/openbox/autostart" << 'OB_AUTO'
## articOs-Welcome-Run-Once
artic-profile --tui &
sed -i -e '/## articOs-Welcome-Run-Once/Q' "$HOME"/.config/openbox/autostart
OB_AUTO

## ── Update xdg dirs ──────────────────────────────────────────────────────────
runuser -l liveuser -c 'xdg-user-dirs-update' 2>/dev/null || true
runuser -l liveuser -c 'xdg-user-dirs-gtk-update' 2>/dev/null || true
xdg-user-dirs-update

## ── Cursor fix ───────────────────────────────────────────────────────────────
rm -rf /usr/share/icons/default

## ── Hide clutter apps ────────────────────────────────────────────────────────
adir="/usr/share/applications"
apps=(avahi-discover.desktop bssh.desktop bvnc.desktop echomixer.desktop \
    envy24control.desktop feh.desktop hdajackretask.desktop \
    lftp.desktop lstopo.desktop qv4l2.desktop qvidcap.desktop \
    thunar-bulk-rename.desktop thunar-settings.desktop \
    thunar-volman-settings.desktop yad-icon-browser.desktop)
for app in "${apps[@]}"; do
    [[ -e "$adir/$app" ]] && sed -i '$s/$/\nNoDisplay=true/' "$adir/$app"
done

echo "articOs airootfs customization complete."
