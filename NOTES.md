# SweetPotatOs — agent / maintainer notes

Durable context for humans and Cursor agents. Prefer this over chat history after a reinstall.

## Repo map

| Repo | Role | Remotes |
|------|------|---------|
| **SweetPotatOs** (this repo) | Archiso profile, ISO build, SourceForge tooling | GitHub `origin`, SourceForge `sourceforge` |
| **SweetPotato** | Desktop theme + `install.sh` (source of truth for Swirl/`~/.config/swirl`/gtk/fastfetch/…) | GitHub `origin` only |

Expected layout on a build machine (siblings):

```text
~/SweetPotato/     # theme
~/SweetPotatOs/    # ISO (this repo)
```

`sync-theme.sh` defaults to `../SweetPotato` (override with `SWEETPOTATO_DIR`).

## Workflow

1. Change theme/desktop in **SweetPotato** first; test on the running session (`~/.config/…`).
2. Run `./sync-theme.sh` from SweetPotatOs to copy into:
   - live home (`$HOME`) — **only on Swirl/Arch**. On a **GNOME/Bluefin** host this is skipped automatically (Papirus + Arch glycin paths blank half the GNOME icons). Pass `--live` only if you really want to clobber the GNOME session; `--iso-only` forces airootfs-only.
   - `profile/airootfs/etc/skel`
   - `profile/airootfs/home/liveuser`
   - system logo dir `profile/airootfs/usr/local/share/sweetpotatos/`
   - `profile/airootfs/etc/fastfetch/config.jsonc`
3. Build packages if needed: `sudo ./build.sh --build-packages` (calamares + swirl + yay-bin/shelly-bin/tera).
4. Build ISO: `sudo ./build.sh`.
5. Publish:
   - Git: push SweetPotato → GitHub; SweetPotatOs → GitHub **and** `sourceforge`.
   - ISO files: `SF_USER=… ./sourceforge/upload.sh` (rsync ISO + `.sha256` + `htdocs/`).

After cloning SweetPotatOs elsewhere, fix `profile/pacman.conf` `[sweetpotatos]` `Server = file://…` to the absolute path of `./repo`.

## Fastfetch logo

- Primary logo is colored **`SPLogo.png`** via **`logo.type: chafa`** (ASCII/blocks in potato orange/red). Do not use raw sixel/PNG/`auto` as primary in foot. Monochrome `SPLogo.asc` is last-resort only.
- Paths:
  - Session / SweetPotato install: `~/.config/fastfetch/SPLogo.png`
  - ISO / system: `/usr/local/share/sweetpotatos/SPLogo.png` (skel + liveuser configs rewritten by `sync-theme.sh` for ISO trees only)
- Canonical PNG lives in `SweetPotato/fastfetch/SPLogo.png`. Ship `chafa` (and keep `imagemagick` optional).

## Lid close → sleep

- Drop-in: `HandleLidSwitch=suspend`, `HandleLidSwitchExternalPower=suspend`, `HandleLidSwitchDocked=ignore`.
- ISO: `profile/airootfs/etc/systemd/logind.conf.d/lid-sleep.conf` (old `do-not-suspend.conf` removed).
- SweetPotato `install.sh` installs `systemd/logind.conf.d/lid-sleep.conf` as `/etc/systemd/logind.conf.d/50-sweetpotato-lid-sleep.conf`.
- **Gotcha:** a leftover `/etc/systemd/logind.conf.d/do-not-suspend.conf` (`HandleLidSwitch=ignore`) sorts **after** `50-…` and wins. Remove it and restart `systemd-logind` on upgraded machines.

## Caffeine vs suspend

- **Mod+c** / `caffeine.sh`: disables **idle** lock/display-off only (`systemd-inhibit --what=idle`).
- Lid-close suspend must keep working while caffeine is on.
- Live ISO: caffeine **on by default** so install is not interrupted by idle lock; lid still suspends via logind.

## Packages / AUR

- No Flatpak/Bazaar. Ship **yay-bin**, **shelly-bin** (Shelly GUI; local `packaging/shelly-bin` from upstream prebuilt release — avoids AUR Anubis / zig), and **tera** (web radio) via the local `repo/` (built from AUR / `packaging/` in `build.sh`).
- Official deps: `base-devel`, `git`, `pacman-contrib`, `fzf`, `github-cli`, `wget`, `python` (mpv already present).
- `packaging/tera`: local PKGBUILD (upstream AUR omits `go` makedepend required by its Makefile).
- `packaging/shelly-bin`: local PKGBUILD wrapping Seafoam Labs release tarball (no Flatpak backend package).

## Live ISO specifics (`sync-theme.sh` injects into liveuser Swirl config)

- Calamares: float window, **Mod+i**, autostart after ~5s (`sweetpotatos-calamares`).
- Liveuser: empty password, sudo NOPASSWD, autologin tty1 → **Swirl** (`sweetpotatos-session`).
- Compositor package: `swirl` in local `repo/` (`packaging/swirl`, `sudo ./build.sh --build-swirl`).
- Bar / IPC / nag: stock from Arch `sway` package. User config lives in `~/.config/swirl/` (never also ship `~/.config/sway/` — Swirl prefers that path first). `include /etc/sway/config.d/*` stays for package drop-ins.
- Session files: do **not** ship `wayland-sessions/*.desktop` in airootfs (conflicts with pacstrap). `swirl.desktop` comes from the swirl package; stock `sway.desktop` is hidden by `sweetpotatos-hide-sway-session.hook`.
- Desktop identity: Arch `sway` drop-in sets `XDG_CURRENT_DESKTOP=sway`; swirl’s `99-swirl-systemd-user.conf` overrides it. Live tty1 also exports Swirl in `sweetpotatos-session`. Fastfetch DE/WM labels are forced to Swirl in the theme config.
- Ly: `waylandsessions = /etc/ly/wayland-sessions` (Swirl only). Pacman hooks **delete** `/usr/share/wayland-sessions/sway.desktop` (Ly ignores Hidden=). Keep the Arch `sway` package only for swaybar/swaymsg/swaynag.
- Ly always lists **root** first. Do **not** ship `/etc/ly/save.txt` with index `0` (that selects root). Calamares `shellprocess@fix-ly` (`sweetpotatos-fix-ly`) removes `liveuser` and writes `save.txt` for `${USER}` after the users step.
- Installed user must be able to `sudo`: airootfs ships `/etc/sudoers.d/10-wheel`; `sweetpotatos-fix-sudo` (from `shellprocess@fix-ly` and again from `cleanup-live`) adds `${USER}` to `wheel`, writes `/etc/sudoers.d/10-installed-user` with an explicit user rule, and uncomments `%wheel` in `/etc/sudoers`. Do not rely only on Calamares `10-installer`.
- After install, `shellprocess@cleanup-live` must remove Install SweetPotatOs / calamares `.desktop` leftovers from the app launcher.
- Default terminal is **foot**; `Mod+Return` / applauncher / networkmanager-dmenu use foot. Do not ship kitty config. Foot must stay opaque (`alpha=1.0`) under **`[colors-dark]`** (foot ≥1.26; do not use deprecated `[colors]`).
- Status bar (`status.sh`) polls every **3s**.
- Ly: `default_input = password` (saved user → type password immediately).
- Session start: `rfkill unblock bluetooth`; one-shot tips via `tips.sh` (live every boot; installed once).
- Enable `bluetooth.service` + `power-profiles-daemon.service` on live/install. Do **not** enable `sshd`, `ModemManager`, or VM guest helpers by default.
- Display layout is managed by **nwg-displays** (GUI) + **kanshi** (daemon). `Mod+Shift+d` or the app launcher launches nwg-displays; it requires `~/.config/sway/` to exist (created by `mkdir -p` wrapper in the Exec/keybind). It saves to `~/.config/sway/outputs`; Swirl config includes that file. kanshi auto-applies `~/.config/kanshi/config` profiles on startup. `wlr-randr` shows current output names/modes. **Do not** ship `~/.config/sway/` in skel — the mkdir wrapper creates it at runtime.
- Wallpaper is managed by **waypaper** (AUR, bundled in local repo). Config at `~/.config/waypaper/config.ini`; default wallpaper is `BindsBG.png` from `~/Pictures/Wallpapers/`. `exec_always waypaper --restore` in Swirl config restores it on login. `Mod+Shift+w` opens the waypaper GUI. The old `wallpaper.sh`, `ensure-wallpaper.sh`, and `wallpaper.conf` are removed.
- Live Calamares keyboard: on Wayland Calamares only updates **locale1**; Swirl ignores it. Live session runs `sweetpotatos-sway-xkb-watch` (busctl poll of locale1 → `swaymsg`). Do **not** use `dbus-monitor --system` for this: liveuser cannot BecomeMonitor on dbus-broker, so the watcher never saw French. Installed user gets `shellprocess@fix-sway-keyboard` (`config-us` / `config-fr`).
- Smoke check: `./scripts/smoke-check.sh`.
- **Gotcha:** shellprocess GS vars must be `${gs[keyboardLayout]}` / `${gs[keyboardVariant]}`. Bare `gs[...]` is passed literally, hits a sed path, and aborts install (seen on 2026.08.12 ISO). Command is prefixed with `-` so a future tweak failure cannot fail the whole install.

## SourceForge

- Project: `sweetpotatos`
- Git: `ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code`
- Files release folder naming: `SF_RELEASE` (e.g. `2026.08.08`) matches ISO name `SweetPotatOs-${SF_RELEASE}-x86_64.iso`
- Web: `sourceforge/htdocs/` → `https://sweetpotatos.sourceforge.io/`
- Optional: short `README.txt` next to the ISO is nice for Files browsers; `.sha256` is the important companion. Full docs stay in GitHub README + htdocs.

## After reinstalling this OS on the build machine

```bash
git clone https://github.com/visnudeva/SweetPotatOs.git
git clone https://github.com/visnudeva/SweetPotato.git
# add SourceForge remote on SweetPotatOs if needed (see sourceforge/SETUP.md)
```

Open `SweetPotatOs` in Cursor. Agents should read this file and `.cursor/rules/project-notes.mdc`. Chat history under `~/.cursor/` is local — back it up separately if you care about old threads.
