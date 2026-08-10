# SweetPotatOs — agent / maintainer notes

Durable context for humans and Cursor agents. Prefer this over chat history after a reinstall.

## Repo map

| Repo | Role | Remotes |
|------|------|---------|
| **SweetPotatOs** (this repo) | Archiso profile, ISO build, SourceForge tooling | GitHub `origin`, SourceForge `sourceforge` |
| **SweetPotato** | Desktop theme + `install.sh` (source of truth for Swirl/`~/.config/sway`/gtk/fastfetch/…) | GitHub `origin` only |

Expected layout on a build machine (siblings):

```text
~/SweetPotato/     # theme
~/SweetPotatOs/    # ISO (this repo)
```

`sync-theme.sh` defaults to `../SweetPotato` (override with `SWEETPOTATO_DIR`).

## Workflow

1. Change theme/desktop in **SweetPotato** first; test on the running session (`~/.config/…`).
2. Run `./sync-theme.sh` from SweetPotatOs to copy into:
   - live home (`$HOME`)
   - `profile/airootfs/etc/skel`
   - `profile/airootfs/home/liveuser`
   - system logo dir `profile/airootfs/usr/local/share/sweetpotatos/`
   - `profile/airootfs/etc/fastfetch/config.jsonc`
3. Build packages if needed: `sudo ./build.sh --build-packages` (calamares + swirl).
4. Build ISO: `sudo ./build.sh`.
5. Publish:
   - Git: push SweetPotato → GitHub; SweetPotatOs → GitHub **and** `sourceforge`.
   - ISO files: `SF_USER=… ./sourceforge/upload.sh` (rsync ISO + `.sha256` + `htdocs/`).

After cloning SweetPotatOs elsewhere, fix `profile/pacman.conf` `[sweetpotatos]` `Server = file://…` to the absolute path of `./repo`.

## Fastfetch logo

- **Do not** use `logo.type: chafa` / PNG as the primary logo in foot: without cell pixel size, fastfetch fails image logos and **falls back to the Arch/Archcraft builtin**.
- Use **`type: file`** + **`SPLogo.asc`** (braille ASCII of the white potato logo).
- Paths:
  - Session / SweetPotato install: `~/.config/fastfetch/SPLogo.asc`
  - ISO / system: `/usr/local/share/sweetpotatos/SPLogo.asc` (skel + liveuser configs rewritten by `sync-theme.sh` for ISO trees only)
- Canonical ASC lives in `SweetPotato/fastfetch/SPLogo.asc`. Regenerate from `WhiteLogo.png` / Downloads logos with chafa symbols if needed, then sync.

## Lid close → sleep

- Drop-in: `HandleLidSwitch=suspend`, `HandleLidSwitchExternalPower=suspend`, `HandleLidSwitchDocked=ignore`.
- ISO: `profile/airootfs/etc/systemd/logind.conf.d/lid-sleep.conf` (old `do-not-suspend.conf` removed).
- SweetPotato `install.sh` installs `systemd/logind.conf.d/lid-sleep.conf` as `/etc/systemd/logind.conf.d/50-sweetpotato-lid-sleep.conf`.
- **Gotcha:** a leftover `/etc/systemd/logind.conf.d/do-not-suspend.conf` (`HandleLidSwitch=ignore`) sorts **after** `50-…` and wins. Remove it and restart `systemd-logind` on upgraded machines.

## Caffeine vs suspend

- **Mod+c** / `caffeine.sh`: disables **idle** lock/display-off only (`systemd-inhibit --what=idle`).
- Lid-close suspend must keep working while caffeine is on.
- Live ISO: caffeine **on by default** so install is not interrupted by idle lock; lid still suspends via logind.

## Live ISO specifics (`sync-theme.sh` injects into liveuser Swirl config)

- Calamares: float window, **Mod+i**, autostart after ~5s (`sweetpotatos-calamares`).
- Liveuser: empty password, sudo NOPASSWD, autologin tty1 → **Swirl** (`sweetpotatos-session`).
- Compositor package: `swirl` in local `repo/` (`packaging/swirl`, `sudo ./build.sh --build-swirl`).
- Bar / IPC / nag: stock from Arch `sway` package. Config stays in `~/.config/sway/`.
- Session files: do **not** ship `wayland-sessions/*.desktop` in airootfs (conflicts with pacstrap). `swirl.desktop` comes from the swirl package; stock `sway.desktop` is hidden by `sweetpotatos-hide-sway-session.hook`.
- Desktop identity: Arch `sway` drop-in sets `XDG_CURRENT_DESKTOP=sway`; swirl’s `99-swirl-systemd-user.conf` overrides it. Live tty1 also exports Swirl in `sweetpotatos-session`. Fastfetch DE/WM labels are forced to Swirl in the theme config.
- Ly: `waylandsessions = /etc/ly/wayland-sessions` (Swirl only). Pacman hooks **delete** `/usr/share/wayland-sessions/sway.desktop` (Ly ignores Hidden=). Keep the Arch `sway` package only for swaybar/swaymsg/swaynag.

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
