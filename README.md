# articOs

> **Adaptive Linux.** Minimal by default. Your shape, your rules.

articOs is a heavily modified fork of [Archcraft](https://archcraft.io) built on a **linux-zen kernel**, with a built-in **profile system**, **automatic snapshots**, **Nix-like containerisation**, and a **hardened security baseline** — all without breaking the Archcraft ecosystem.

---

## Key Features

| Feature | Description |
|---|---|
| **linux-zen kernel** | Low-latency, desktop-optimised kernel replacing `linux` |
| **Profile System** | Switch your entire environment: dev, hacker, gamer, home, robotics, creative, minimal |
| **Super+P keybind** | Rofi-powered profile picker from the desktop |
| **artic-snapshot** | Unified snapshot CLI wrapping btrfs/snapper + timeshift |
| **artic-box** | Container & isolated env manager (distrobox, flatpak, nix-shell) |
| **artic-secure** | One-command security hardening: AppArmor, UFW, fail2ban, Firejail |
| **Minimal ISO** | Install base, choose more via `artic-profile` or `pacman`/AUR/apt |
| **GitHub Actions** | Reproducible ISO builds with signing and QEMU smoke tests |

---

## Profiles

Select a profile interactively:

```bash
artic-profile          # TUI menu
artic-profile dev      # activate directly
```

Or from the desktop: **Super+P**

### Available Profiles

| Profile | Description |
|---|---|
| `dev` | Compilers, LSPs, Docker, VS Code, neovim, lazygit |
| `hacker` | Metasploit, Wireshark, Ghidra, Burp Suite, CTF tools |
| `gamer` | Steam, Lutris, Wine/Proton, GameMode, MangoHud |
| `home` | Firefox, LibreOffice, VLC, Thunderbird, KeePassXC |
| `robotics` | ROS2, Gazebo, Arduino, OpenOCD, FPGA toolchain |
| `creative` | GIMP, Blender, Kdenlive, Ardour, OBS, DaVinci Resolve |
| `minimal` | Just the essentials — neovim, tmux, git, zsh, fzf |

### Custom Profiles

Create `~/.config/artic/profiles/myprofile.conf`:

```bash
DESCRIPTION="My custom setup"
ICON="🛠️"
PACMAN_PACKAGES=(neovim tmux)
AUR_PACKAGES=(lazygit)
FLATPAK_APPS=(org.mozilla.firefox)
SERVICES_ENABLE=(docker)
SYSCTL_SETTINGS=("vm.swappiness=5")
ARTIC_ENV=('export EDITOR=nvim')
```

Then: `artic-profile myprofile`

---

## Snapshots

```bash
artic-snapshot setup              # one-time setup (auto on install)
artic-snapshot create "my note"   # create a snapshot now
artic-snapshot list               # list all snapshots
artic-snapshot restore 42         # restore snapshot #42
artic-snapshot diff 10 20         # diff between two snapshots
```

- On **btrfs**: uses snapper with timeline cleanup + grub-btrfs boot entries
- On **ext4**: uses timeshift (rsync mode)
- **snap-pac**: auto-snapshot before every `pacman` operation

---

## Containers & Isolated Environments

```bash
# Run Ubuntu alongside Arch
artic-box create ubuntu
artic-box enter ubuntu
artic-box install ubuntu vim curl nodejs

# Export a GUI app to the host
artic-box export ubuntu firefox

# Isolated dev environments (no root needed)
artic-box env new myproject python
source ~/.config/artic/envs/myproject/activate.sh

# Nix shell
artic-box env new myenv nix
# edit ~/.config/artic/envs/myenv/shell.nix
nix-shell ~/.config/artic/envs/myenv/shell.nix

# Available box images
artic-box create kali     # Kali Linux
artic-box create ros2     # ROS2 Humble
artic-box create fedora   # Fedora 40
artic-box create cuda     # CUDA dev environment
```

---

## Security

```bash
artic-secure harden        # full hardening (interactive)
artic-secure kernel        # sysctl hardening only
artic-secure firewall      # UFW: deny-in, allow-out, rate-limit SSH
artic-secure ssh           # SSH key-only, disable root, modern ciphers
artic-secure apparmor      # enable AppArmor enforce mode
artic-secure fail2ban      # SSH brute-force protection
artic-secure firejail      # sandbox browsers and risky apps
artic-secure audit         # run lynis security audit
```

---

## Package Installation

articOs supports all these sources — use whatever fits:

```bash
# Arch official + AUR
sudo pacman -S vim
paru -S visual-studio-code-bin

# Flatpak (sandboxed)
flatpak install flathub org.gimp.GIMP

# apt/dnf inside a container (doesn't touch host)
artic-box install ubuntu python3-opencv

# Profile-defined (declarative)
artic-profile dev          # installs everything in dev.conf
```

---

## Building the ISO

### Locally (Arch Linux host)

```bash
sudo pacman -S archiso
sudo mkarchiso -v -w /tmp/build -o /tmp/out profile/
```

### Via GitHub Actions

Push to `main` → workflow auto-builds. Tag a release:

```bash
git tag v2025.05.01
git push origin v2025.05.01
```

The workflow will:
1. Validate all scripts (shellcheck) and package lists
2. Build the ISO in an Arch container
3. Run a 30-second QEMU smoke test
4. GPG sign (if `GPG_PRIVATE_KEY` secret set)
5. Create a GitHub Release with checksums

### Verify download

```bash
sha256sum -c articOs-v2025.05.01-x86_64.iso.sha256
gpg --verify articOs-v2025.05.01-x86_64.iso.asc
```

---

## First Boot

After installing articOs, run the setup wizard:

```bash
artic-install
```

This walks you through: profile selection, snapshot setup, security level, container support, and Flatpak.

---

## What's kept from Archcraft

- All Archcraft window manager configs (Openbox, bspwm)
- SDDM theme, Plymouth theme, GRUB theme
- Archcraft package repository integration
- Archcraft fonts, icons, cursors, wallpapers
- Archcraft installer (Calamares + ABIF)

## What articOs adds / changes

- `linux-zen` replaces `linux`
- `artic-profile` profile system
- `artic-snapshot` snapshot manager
- `artic-box` container manager
- `artic-secure` security tools
- `artic-install` first-boot wizard
- `snap-pac` auto-snapshots on pacman
- `firejail`, `fail2ban`, `audit` in base
- Hardened sysctl defaults
- GitHub Actions CI/CD
- `distrobox`, `podman`, `flatpak` in base
- Super+P desktop keybind for profile picker
- `paru` alongside `yay`
- `btop`, `bat`, `eza`, `starship`, `zoxide`, `fzf`, `ripgrep` in base

---

## License

GPL-3.0 — same as Archcraft. articOs-specific additions are original work.

---

*articOs — because your OS should adapt to you, not the other way around.*
