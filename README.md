# SweetPotatOs

<p align="center">
  <img src="assets/SweetPotatOs.png" alt="SweetPotatOs" width="220">
</p>

Live graphical **Arch Linux** ISO with the [SweetPotato](https://github.com/visnudeva/SweetPotato) Sway desktop and a **Calamares** installer.

Colors: **#a73b50** potato red · **#f79b29** potato orange · **#1d1f21** charcoal

## What you get

- Live Sway session (`liveuser`, empty password, sudo without password)
- Autologin on tty1 → SweetPotato desktop (foot, Thunar, mako, NetworkManager, …)
- Installer autostarts on the live desktop; also **Mod+i**, desktop *Install SweetPotatOs*, or `sweetpotatos-calamares`
- Installed system uses the live squashfs, GRUB, and **Ly** on tty2

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
| Wi‑Fi | `Mod+n` |
| Wallpaper | `Mod+Shift+w` |
| Screenshot | `Print` · region `Mod+Shift+Print` |
| Screen record | `Mod+Print` (toggle, region + audio → `~/Videos`) |
| Installer | `Mod+i` |

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
├── assets/           # README / branding art (SweetPotatOs.png, SPLogo.png)
├── build.sh          # --build-calamares | mkarchiso wrapper
├── profile/          # archiso profile
│   ├── profiledef.sh
│   ├── packages.x86_64
│   ├── pacman.conf
│   └── airootfs/     # live overlay (skel, Calamares, NetworkManager, …)
├── repo/             # local pacman repo (calamares *.pkg.tar.*)
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

- Theme / post-install script: https://github.com/visnudeva/SweetPotato

## License

SweetPotato theme configs follow that repository’s license.  
Archiso profile layout follows Arch Linux archiso licensing.
