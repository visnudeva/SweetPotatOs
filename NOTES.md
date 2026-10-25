# SweetPotatOs — agent / maintainer notes

Durable context for humans and Cursor agents. Prefer this over chat history after a reinstall.

**Full restore backup (host wipe / new Arch machine):** see [`AGENT_MEMORY_BACKUP.md`](./AGENT_MEMORY_BACKUP.md) — ISO recipe, hard rules, SourceForge/SSH checklist, and the first Cursor prompt to paste after reinstall.

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
3. Build packages if needed: `sudo ./build.sh --build-packages` (calamares + swirl + yay-bin/shelly-bin/localsend-bin/spore/tuber/brave-origin-bin).
4. Build ISO: `sudo ./build.sh`.
5. Publish:
   - Git: push SweetPotato → GitHub; SweetPotatOs → GitHub **and** `sourceforge`.
   - ISO files only: `SF_USER=… ./sourceforge/upload.sh` (rsync ISO + `.sha256` + `htdocs/`).
   - Point releases only — no in-place overlay upgrade channel. Desktop/theme on other distros: SweetPotato `install.sh`.
   - Draft for a future Ryoku-style package + sprout channel (not built yet): [`docs/updates-design.md`](./docs/updates-design.md).

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
- Power menu sleep uses `suspend.sh` (clears leftover caffeine inhibitors, then `systemctl suspend`).
- `swayidle` / caffeine lock after idle and use `after-resume 'swaymsg "output * power on"'` so lid wake is less likely to leave a black panel. Do **not** use idle `output * power off` (asleep LED, no wake on some laptops). Do **not** use `output * enable`. Do **not** take a `systemd-inhibit` lock across sleep. AC plug/unplug has no SPO handler — if that powers the machine off, suspect firmware/hardware.

## Caffeine vs suspend

- **Mod+c** / `caffeine.sh`: keeps the screen on while the lid is open by running swayidle with no idle timeouts. The before-sleep lock and after-resume panel power-on stay, matching the normal watcher. No compositor output power-off in either mode. Do **not** take a `systemd-inhibit` lock. A lock held across lid sleep leaves some laptops unable to wake.
- Lid close, wake, and power off stay the same with caffeine on or off. Logind still suspends on lid close.
- **Mod+Escape**: sleep via `suspend.sh`; power off / reboot via `poweroff.sh` (drops leftover inhibitors, then `systemctl … --ignore-inhibitors`). Do not inhibit `sleep`, `shutdown`, or `handle-lid-switch`.
- Live ISO: caffeine **on by default** so install is not interrupted by idle lock; lid still suspends via logind.

## Packages / AUR

- No Flatpak/Bazaar. Ship **yay-bin**, **shelly-bin**, **localsend-bin**, **brave-origin-bin**, **spore**, **tuber**, and **swaylock-effects** via the local `repo/` (built in `build.sh`) for ISO builds.
- **Installed-system package channel (GitHub, not SourceForge):**
  - **Primary delivery for Third Harvest+ installs:** theme/desktop fixes ship via
    `sweetpotatos-update` — bump `packaging/sweetpotatos` (and swirl when needed),
    rebuild into `repo/`, then `./scripts/publish-repo.sh testing`. Point-release ISOs are
    for new installs / marketing, not required for existing boxes.
  - **Stay on testing until the user says to push to stable.** A plain “publish”
    means the testing release. Live `pacman-repo` only after an explicit request
    such as “push to stable”.
  - Testing: `./scripts/publish-repo.sh testing` → prerelease tag `pacman-repo-testing`
    (`https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo-testing`).
    On a SweetPotatOs install, `sudo sweetpotatos-update --testing` tracks that tag
    until `sudo sweetpotatos-update --stable`. Do not point this Ryoku host at either tag.
  - Stable (only when asked): `./scripts/publish-repo.sh` → GitHub release tag `pacman-repo`
  - Live server: `https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo`
  - CLI: `sweetpotatos-update` (installs new SPO packages on the channel + upgrades existing) + `sweetpotatos-sprout` (shipped `~/.config` with user overlay; also refreshes shipped wallpapers into `~/Pictures/Wallpapers` and `~/.local/share/backgrounds` without changing waypaper’s active selection or deleting user extras)
  - Weekly notice: `sweetpotatos-update-check.timer` (Monday 10:00, or at next boot if the machine was off) runs `sweetpotatos-update --check`. A desktop notification is shown only when channel packages would install or upgrade. The live ISO skips it (`/run/archiso`). Login shows a missed notice once via the user unit `sweetpotatos-update-notify.service`.
  - After `sweetpotatos-update` installs or upgrades packages, a desktop note shows what changed. The log is `packaging/sweetpotatos/update-news` (shipped as `/usr/share/sweetpotatos/update-news`). Append a block (`@pkgver-pkgrel`, then the note). Do not delete earlier blocks. One notification is shown for every block newer than the version that was installed, oldest first. A file with no `@version` blocks is still a single note; if that text is unchanged, the note names the packages that were installed or upgraded. The updater runs as root and delivers the note with `runuser` into the desktop session (nested `sudo` often waits for a password and the bubble never appears). The script that performs the upgrade has to be the one that knows how to notify — the first install of this feature is applied by the previous script, so the note shows on the following update. The version from before the transaction is passed in, and the notify script also reads the latest `upgraded sweetpotatos (old -> new)` line in pacman.log so a jump across releases still lists the notes in between.
  - Unit tests: `./tests/run.sh`
  - SourceForge Files stays **ISO + project web only** (see `docs/updates-design.md`)
- Official deps: `base-devel`, `git`, `pacman-contrib`, `fzf`, `github-cli`, `wget`, `python` (mpv already present).
- `packaging/shelly-bin`: local PKGBUILD wrapping Seafoam Labs release tarball (no Flatpak backend package).
- `packaging/spore`: local PKGBUILD for visnudeva/spore (Go TUI radio + local files; optional `ffmpeg` for some codecs).
- `packaging/tuber`: local PKGBUILD for visnudeva/tuber (Go BitTorrent TUI; replaces transmission-gtk; Mod+t).
- `packaging/laniakea`: opt-in generative wallpaper app (sibling `GITHUB/laniakea`; testing channel first). Live draw + masks → PNG → swaybg/waypaper. Not on the ISO by default.
- `packaging/swaylock-effects`: jirutka fork with lock-screen clock; replaces Arch `swaylock` (ISO + `sweetpotatos-update`).

## Live ISO specifics (`sync-theme.sh` injects into liveuser Swirl config)

- Calamares: float window, **Mod+i**, autostart after ~5s (`sweetpotatos-calamares`).
- Liveuser: empty password, sudo NOPASSWD, autologin tty1 → **Swirl** (`sweetpotatos-session`).
- Compositor package: `swirl` in local `repo/` (`packaging/swirl`, `sudo ./build.sh --build-swirl`).
- Bar / IPC / nag / menu: built with the swirl package (`swirlbar`, `swirlmsg`, `swirlnag`, `swirlmenu`). `swaybar`, `swaymsg`, and `swaynag` are symlinks to those. Do not install the Arch `sway` package. User config lives in `~/.config/swirl/` (never also ship `~/.config/sway/` — Swirl prefers that path first). `include /etc/sway/config.d/*` stays for package drop-ins. Durable user keybinds: `~/.config/swirl/config.d/user` (seed-only; sprout never overwrites). `swayidle`, `swaybg`, `swaylock-effects`, and `swayimg` stay separate packages. The swirl package depends on foot, wmenu, swaybg, swayidle, and swaylock-effects, and ships `/etc/swirl/config` plus `/usr/share/swirl/` so a machine with no home config still gets a session. `~/.config/swirl/config` wins, so the SweetPotatOs desktop is unchanged.
- Session files: do **not** ship `wayland-sessions/*.desktop` in airootfs (conflicts with pacstrap). `swirl.desktop` comes from the swirl package; stock `sway.desktop` is hidden by `sweetpotatos-hide-sway-session.hook`.
- Desktop identity: Arch `sway` drop-in sets `XDG_CURRENT_DESKTOP=sway`; swirl’s `99-swirl-systemd-user.conf` overrides it. Live tty1 also exports Swirl in `sweetpotatos-session`. Fastfetch DE/WM labels are forced to Swirl in the theme config.
- Ly: `waylandsessions = /etc/ly/wayland-sessions` (Swirl only). Pacman hooks **delete** `/usr/share/wayland-sessions/sway.desktop` (Ly ignores Hidden=). The ISO does not install the Arch `sway` package.
- Ly always lists **root** first. Do **not** ship `/etc/ly/save.txt` with index `0` (that selects root). Calamares `shellprocess@fix-ly` (`sweetpotatos-fix-ly`) removes `liveuser` and writes `save.txt` for `${USER}` after the users step.
- Installed user must be able to `sudo`: airootfs ships `/etc/sudoers.d/10-wheel`; `sweetpotatos-fix-sudo` (from `shellprocess@fix-ly` and again from `cleanup-live`) adds `${USER}` to `wheel`, writes `/etc/sudoers.d/10-installed-user` with an explicit user rule, and uncomments `%wheel` in `/etc/sudoers`. Do not rely only on Calamares `10-installer`.
- After install, `shellprocess@cleanup-live` must remove Install SweetPotatOs / calamares `.desktop` leftovers from the app launcher.
- Default terminal is **foot**; `Mod+Return` / applauncher / networkmanager-dmenu use foot. Do not ship kitty config. Foot must stay opaque (`alpha=1.0`) under **`[colors-dark]`** (foot ≥1.26; do not use deprecated `[colors]`).
- Interactive shell: **fish** is installed (`packages.x86_64` and a `sweetpotatos` dependency, so `sweetpotatos-update` pulls it). Foot starts fish (`shell=/usr/bin/fish`). Login stays bash. Desktop scripts stay `#!/usr/bin/env bash`.
- Status bar (`status.sh`) polls every **3s**. The bar block sets `id potato`, `swaybar_command swirlbar` (PATH binary only — `execvp` does not expand `~`; `swaybar` is a symlink). `swaybar-quiet-shutdown.patch` demotes disconnect/tray teardown logs and redirects the bar child stderr to `/dev/null` so logout/poweroff does not flash spam on the login VT, `tray_padding 4` (Papirus tray icons closer to Nerd Font status size), `scroller_indicator no` and `trails_indicator no` so swirlbar does not draw scroll arrows, the eye, or `T0/0 (0)`. Status text and workspace discs are ink-centered to match the tray (no pango `rise`). When frames are on, `frame.sh` owns `bar potato gaps` / `border_radius` / `border` (floating swirlbar with an 8px radius and 2px accent edge; `swaybar-rounded-frame.patch` + `swaybar-gaps-margin-refresh.patch` so runtime gap toggles re-push layer margins without a reload), sets an 8px window inner gap (including a lone window), and switches `hide_edge_borders none` + `smart_borders off` so the focused border stays visible (`hide-edge-borders-gaps.patch` skips edge hiding while `gaps_inner > 0` or overview is open). `overview-border-clip.patch` keeps overview frames visible (round scaled tile boxes so neighbours do not overlap; Escape exits overview). Autotile only mirrors per-workspace inner gaps and must not touch bar chrome (a theme `swaymsg reload` resets the bar block; `exec_always frame.sh apply` re-applies after ~0.6s). Frames off restores flush bar, gap 0, and `hide_edge_borders smart`. Always use the explicit bar id — a mis-targeted `bar <id> …` can spawn a second bar (defaults to **bottom**). `swirlmenu` reads those bar gaps and height and draws a matching-height rounded, bordered menu at the bottom (`wmenu-layer-margins.patch`). The power menu (`power-menu.sh` via Mod+Escape) is one swirlnag row (`swaynag-single-row.patch`) with capsule buttons (`swaynag-rounded-buttons.patch`), Nerd Font icons (lock / sleep / logout / reboot / power), and no X dismiss control (`swaynag-power-menu.patch`). With frames on it floats in the same rounded accent panel as swirlbar (`swaynag-rounded-panel.patch`). Escape or a click outside the bar dismisses; Enter only confirms when there is a single action button (`swaynag-keyboard.patch`).
- Ly: `default_input = password` (saved user → type password immediately).
- Session start: `rfkill unblock bluetooth`; keybind reminder via `tips.sh` → Mod+? cheatsheet. The reminder is once per session unless the user turns it off: focus the cheatsheet and press `x` (`~/.config/sweetpotatos/login-tip` is `off`). `x` again turns it back on. `Mod+?` still opens the page.
- Enable `bluetooth.service` + `power-profiles-daemon.service` on live/install. Do **not** enable `sshd`, `ModemManager`, or VM guest helpers by default.
- Display layout is managed by **nwg-displays** (GUI) + saved **`~/.config/sway/outputs`**. App launcher entry is **Displays** (`GenericName=nwg-displays`, search `nwg`) — same binary as terminal `nwg-displays`. Desktop `Exec` must be **`sweetpotatos-displays`** on PATH (not `%h/…` — j4-dmenu-desktop does not expand it; not `bash -lc '~…'`). `Mod+Ctrl+d` opens the swirl wrapper directly. Apply in Displays saves the layout. The swirl wrapper creates empty `outputs`/`workspaces` before parse; kanshi profiles are generated from `outputs` (no `mode preferred` reset). **Do not** ship `~/.config/sway/` in skel.
- Wallpaper is managed by **waypaper** (AUR, bundled in local repo). Config at `~/.config/waypaper/config.ini`; default wallpaper is `SPONeonKanjiDefault.png` from `~/Pictures/Wallpapers/`. `exec_always waypaper --restore` in Swirl config restores it on login. `Mod+Ctrl+w` opens the waypaper GUI. Corners and gaps are `Mod+Ctrl+g`. Do not ship UsefulBinds/BindsBG. Keybinds tip: `tips.sh` points at `Mod+?` cheatsheet. Shipped copies live in the **sweetpotatos** package at `/usr/share/sweetpotato/backgrounds/` (not under `/usr/share/backgrounds/`, which conflicts with ISO leftovers on upgrade); `sweetpotatos-sprout` refreshes those into the user wallpaper folders but does not switch the active waypaper selection.
- Live Calamares keyboard: on Wayland Calamares only updates **locale1**; Swirl ignores it. Live session runs `sweetpotatos-sway-xkb-watch` (busctl poll of locale1 → `swaymsg`). Do **not** use `dbus-monitor --system` for this: liveuser cannot BecomeMonitor on dbus-broker, so the watcher never saw French. Installed user gets `shellprocess@fix-sway-keyboard`, which sets `xkb_layout` and leaves the number-row binds in place.
- NVIDIA drivers: do **not** put `nvidia-open` / `nvidia-utils` in `packages.x86_64` (they blacklist nouveau and break AMD/Intel). Calamares shows a Notes page about needing internet; `shellprocess@install-nvidia` (`sweetpotatos-install-nvidia`) detects Turing+ (PCI id ≥ `0x1e00`) after `networkcfg` and installs `nvidia-open` + `nvidia-utils` only when online. Offline / no GPU / older cards soft-skip and keep Mesa/nouveau. Prefixed with `-` so a failed download cannot abort the install.
- Smoke check: `./scripts/smoke-check.sh`. Unit tests: `./tests/run.sh`.
- **Gotcha:** shellprocess GS vars must be `${gs[keyboardLayout]}` / `${gs[keyboardVariant]}`. Bare `gs[...]` is passed literally, hits a sed path, and aborts install (seen on 2026.08.12 ISO). Command is prefixed with `-` so a future tweak failure cannot fail the whole install.

## Backlog / ideas (not started)

### Theme selector (hue + dark/light)

Goal: a small GUI so users can recolor the desktop without editing configs by hand.

**Controls (agreed direction)**
- **Toggle:** Dark / Light (charcoal surfaces ↔ light surfaces; not a charcoal hue slider — near-grey has no useful hue).
- **Slider 1:** hue of SPO pink/red (`#a73b50`).
- **Slider 2:** hue of SPO orange (`#f79b29`).

**Apply path (MVP)**
1. Store user hues + mode under `~/.config/sweetpotatos/` (survive `sweetpotatos-update` / sprout).
2. Generate a small palette (hex) from base HSL/OKLCH + hue offsets.
3. Write the consumers that are easy to reload: **Swirl** client/colors, **swaylock**, **mako**, **foot**.
4. Reload Swirl (`Mod+Shift+c`) + restart mako/foot as needed. Not true live-preview everywhere.

**Harder later:** full GTK theme regen (apps often need restart); bar if it hardcodes colors.

**Light-mode caveat:** needs a real light text/border set for contrast — don’t only swap the charcoal hex.

**Build-host rule (Ryoku):** develop/publish SweetPotatOs packages without installing them on this host. Do **not** run SPO lockers / sprout / `sweetpotatos-update` here. `build.sh` must **never** add `[sweetpotatos]` / `sweetpotatos-local.conf` to the host’s `/etc/pacman.conf`.

**After any SweetPotatOs build/publish session on this machine — clean Ryoku before stopping:**
1. Remove host pacman wiring if present: drop `Include = /etc/pacman.d/sweetpotatos-local.conf` from `/etc/pacman.conf`; delete `/etc/pacman.d/sweetpotatos-local.conf` (+ `.bak`) and any `/var/lib/pacman/sync/sweetpotatos.*`.
2. Confirm `grep -r sweetpotatos /etc/pacman.conf /etc/pacman.d/` is empty (aside from intentional unrelated files).
3. Confirm `sudo pacman -Sy` (or a dry `pacman -S --print-format '%n' <pkg>`) works without “database file for 'sweetpotatos'”.
4. Do not leave SPO packages installed on Ryoku (`pacman -Q sweetpotatos swirl` should be empty unless the user asked otherwise).

## SourceForge

- Project: `sweetpotatos` — **ISO downloads + project web only** (keep Files clean; no pacman `repo/` tree).
- Git mirror: `ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code`
- Files release folder naming: `SF_RELEASE` (e.g. `2026.08_First_Harvest`) with ISO `Sweetpotatos_2026.08_First_Harvest.iso`
- Web: `sourceforge/htdocs/` → `https://sweetpotatos.sourceforge.io/`
- Optional: short `README.txt` next to the ISO is nice for Files browsers; `.sha256` is the important companion. Full docs stay in GitHub README + htdocs.
- Optional cleanup of leftover Files/`repo/` (obsolete overlay mirror): `./sourceforge/remove-repo.sh`.

## After reinstalling this OS on the build machine

Follow **`AGENT_MEMORY_BACKUP.md`** (sections 0–1 and 7). Short version:

```bash
git clone https://github.com/visnudeva/SweetPotatOs.git
git clone https://github.com/visnudeva/SweetPotato.git
# add SourceForge remote on SweetPotatOs if needed (see sourceforge/SETUP.md)
# fix profile/pacman.conf [sweetpotatos] Server= to this clone's repo/
```

Open `SweetPotatOs` in Cursor. Agents should read `AGENT_MEMORY_BACKUP.md`, this file, and `.cursor/rules/project-notes.mdc`. Chat history under `~/.cursor/` is local — back it up separately if you care about old threads. Before wiping Bluefin, also copy `~/.ssh/id_ed25519_sourceforge*` (and optionally `out/` + `repo/`).
