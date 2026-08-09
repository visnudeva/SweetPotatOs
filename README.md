# SweetPotatOs

<p align="center">
  <img src="assets/Screenshot.png" alt="SweetPotatOs desktop" width="920"
       style="border-radius: 12px; max-width: 100%; height: auto;">
</p>

<table>
  <tr>
    <td>
      <strong>SweetPotatOs is an Arch-based Linux distro: a live graphical ISO with the SweetPotato Sway desktop and a Calamares installer, built to revive slow old potato PCs and make them sweet again.
<br>
    </td>
    <td>
  <img src="assets/SweetPotatOs.png" alt="SweetPotato" width="220">
</td>
  </tr>
</table>

## What you get

- Live Sway session (`liveuser`, empty password, sudo without password)
- Autologin on tty1 → SweetPotato desktop (foot, Thunar, mako, NetworkManager, …)
- Installer autostarts on the live desktop; also **Mod+i**, desktop *Install SweetPotatOs*, or `sweetpotatos-calamares`
- Installed system uses the live squashfs, GRUB, and **Ly** on tty2

## Download

Get the ISO and `.sha256` from SourceForge Files (newest release folder):

**[Download SweetPotatOs](https://sourceforge.net/projects/sweetpotatos/files/)** · [Project page](https://sourceforge.net/projects/sweetpotatos/)

Verify after download:

```bash
sha256sum -c SweetPotatOs-*-x86_64.iso.sha256
```

To publish a new build from this repo:

```bash
SF_USER=your_sourceforge_username SF_RELEASE=YYYY.MM.DD ./sourceforge/upload.sh
```

Then in SourceForge: Files → that release → ⓘ on the `.iso` → set as default download.

## Prerequisites

- Arch-based build host
- Root privileges (`mkarchiso`)
- Packages: `archiso`, `base-devel`, `git`
- Local **Calamares** package (AUR — not in official repos)

## Build

```bash
git clone https://github.com/visnudeva/SweetPotatOs.git
cd SweetPotatOs

# First time only — build Calamares into ./repo
sudo ./build.sh --build-calamares

# Build the ISO
sudo ./build.sh
```

ISO output: `out/SweetPotatOs-*.iso`  
Work tree: `work/` (removed automatically at the start of each ISO build)

### Local Calamares repo

`profile/pacman.conf` includes:

```ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = file:///ABS/PATH/TO/SweetPotatOs/repo
```

Update the `Server =` path if you clone the repo somewhere other than `/home/visnudeva/SweetPotatOs`.

## Live session

| Item | Value |
|------|--------|
| User | `liveuser` |
| Password | empty (Enter) |
| Desktop | Sway + SweetPotato |
| Caffeine | **on by default** (no sleep/lock during install) |

### Useful binds

| Bind | Action |
|------|--------|
| `Mod+n` | Wi‑Fi / NetworkManager |
| `Mod+Space` | App launcher |
| `Mod+w` | Web browser (firefox) |
| `Mod+f` | File manager (thunar) |
| `Mod+e` | IDE (geany) |
| `Mod+Return` | Terminal (foot) |
| `Mod+Shift+w` | Wallpaper selector |
| `Print` | Screenshot → `~/Pictures/Screenshots` (+ clipboard) |
| `Mod+Shift+Print` | Region screenshot |
| `Mod+Print` | Screen record toggle (region + audio → `~/Videos`) |
| `Mod+q` | Kill focused window |
| `Mod+number` | Change workspaces |
| `Mod+l` | Lock (swaylock) |
| `Mod+c` | Caffeine toggle (on by default on live ISO) |
| `Mod+i` | Installer (Calamares) |
| `Mod+Shift+e` | Exit Sway |
| `Mod+o` | Power off |
| `Mod+Shift+c` | Reload config |

`Mod` is usually the Super/Windows key.


## Write ISO to USB

On a SweetPotato desktop, **Disks** (gnome-disks) → select USB → *Restore Disk Image…*  
(Polkit rules in SweetPotato allow `wheel` users to do this on Sway.)

Or:

```bash
lsblk   # find the USB disk, e.g. /dev/sdX — not a partition
sudo dd if=out/SweetPotatOs-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Layout

```
SweetPotatOs/
├── assets/           # README / branding art (Screenshot.png, SweetPotatOs.png, SPLogo.png)
├── build.sh          # --build-calamares | mkarchiso wrapper
├── profile/          # archiso profile
│   ├── profiledef.sh
│   ├── packages.x86_64
│   ├── pacman.conf
│   └── airootfs/     # live overlay (skel, Calamares, NetworkManager, …)
├── repo/             # local pacman repo (calamares *.pkg.tar.*)
├── sourceforge/      # SourceForge project web + upload.sh (rsync)
├── out/              # built ISOs (gitignored)
└── work/             # mkarchiso work dir (gitignored)
```

Theme files are mirrored from [SweetPotato](https://github.com/visnudeva/SweetPotato) into `profile/airootfs/etc/skel` and `home/liveuser`. Re-sync after theme updates:

```bash
./sync-theme.sh
```


## Known limitations

- First ISO build needs Calamares present in `repo/`
- `unpackfs` expects the ISO mounted at `/run/archiso/bootmnt/spotato/...`
- Desktop stack → large ISO

## Related

- Theme / post-install script to install on another distro: https://github.com/visnudeva/SweetPotato

## License

SweetPotato theme configs follow that repository’s license.  
Archiso profile layout follows Arch Linux archiso licensing.
