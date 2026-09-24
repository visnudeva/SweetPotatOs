# SweetPotatOs — agent memory backup (restore after host wipe)

**Purpose:** Full durable memory for Cursor agents and humans after reinstalling the build machine (e.g. leave Bluefin/GNOME → Arch-based host). Prefer this + `NOTES.md` + `.cursor/rules/project-notes.mdc` over chat history.

**Snapshot date:** 2026-09-13 (Bluefin host, Third Harvest era)  
**Maintainer / SF / GitHub user:** `visnudeva`

---

## 0) Before you wipe Bluefin — copy these off-disk

Chat history and SSH keys do **not** live in git. Back them up separately (USB / other machine):

| What | Typical path on this Bluefin host | Why |
|------|-----------------------------------|-----|
| This repo + sibling theme | `/var/home/visnudeva/code/GITHUB/SweetPotatOs` + `…/SweetPotato` | Source of truth; push any uncommitted work first if you care |
| SourceForge SSH key | `~/.ssh/id_ed25519_sourceforge` (+ `.pub`) | Git mirror + FRS rsync uploads |
| GitHub SSH/HTTPS creds | `~/.ssh/id_*`, `gh` auth, `~/.gitconfig` | Clone/push |
| Cursor project data (optional) | `~/.cursor/projects/…SweetPotatOs/` (agent-transcripts, etc.) | Old chat threads only — not required if this file is current |
| Built ISO(s) | `SweetPotatOs/out/*.iso` (+ `.sha256`) | Avoid rebuild if you still need the bits |
| Local pacman packages | `SweetPotatOs/repo/*.pkg.tar.*` | Speeds first ISO build (rebuildable) |

**Uncommitted on 2026-09-13 (push or stash before wipe if needed):**

- Swirl config / cheatsheet under `profile/airootfs/{etc/skel,home/liveuser}/.config/swirl/`
- Minor `sourceforge/htdocs/changelog.html` edits
- Build logs / `sourceforge/bootstrap-repo-stage/` (usually do **not** commit)

`repo/` and `out/` are local artifacts (often gitignored) — copy if you want a faster restore.

---

## 1) Restore on the new Arch-based host

### 1.1 Clone siblings (expected layout)

```bash
mkdir -p ~/code/GITHUB   # or wherever; keep them siblings
cd ~/code/GITHUB
git clone https://github.com/visnudeva/SweetPotatOs.git
git clone https://github.com/visnudeva/SweetPotato.git
```

`sync-theme.sh` defaults to `../SweetPotato` (override: `SWEETPOTATO_DIR`).

### 1.2 SourceForge git remote (SweetPotatOs only)

```bash
cd SweetPotatOs
# Restore id_ed25519_sourceforge into ~/.ssh and add .pub at:
#   https://sourceforge.net/auth/shell_services
git remote add sourceforge ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code
# remotes should be:
#   origin      https://github.com/visnudeva/SweetPotatOs.git
#   sourceforge ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code
```

SweetPotato: GitHub `origin` only.

### 1.3 Fix local pacman Server path

`profile/pacman.conf` `[sweetpotatos]` must point at **this** clone’s `repo/`:

```ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = file:///ABS/PATH/TO/SweetPotatOs/repo
```

(`build.sh` also rewrites this temporarily during ISO build.)

### 1.4 Host packages

```bash
sudo pacman -S --needed archiso base-devel git pacman-contrib
```

On **native Arch**, use `sudo ./build.sh` (no Podman).  
Bluefin/Fedora used `sudo ./run-container-build.sh` → Arch container (`.container-build.sh`). Keep those scripts for non-Arch hosts; prefer native on Arch.

### 1.5 Open in Cursor so agents regain memory

1. Open the **SweetPotatOs** folder in Cursor.
2. Agents auto-load `.cursor/rules/project-notes.mdc` (`alwaysApply`).
3. Tell the agent (first message after restore):

   > Read `AGENT_MEMORY_BACKUP.md`, then `NOTES.md`. We are continuing SweetPotatOs ISO work on a new Arch host.

That is enough to restore project rules; old Bluefin chat threads are optional.

---

## 2) End-to-end: create a SweetPotatOs ISO

### Workflow (theme → sync → packages → ISO → publish)

1. **Theme / desktop changes** → edit **SweetPotato** first; test on a Swirl session (`~/.config/…`).
2. From SweetPotatOs: `./sync-theme.sh`
   - Copies into airootfs skel + liveuser + system logo + fastfetch ISO paths.
   - On **GNOME/Bluefin**: skips `$HOME` automatically (Papirus/glycin would blank GNOME icons). Never pass `--live` on GNOME.
   - On **Swirl/Arch** build+desktop host: live `$HOME` sync is OK (default). Use `--iso-only` to skip home.
3. **Packages into `./repo`:** `sudo ./build.sh --build-packages`  
   Builds: calamares (AUR), swirl, sweetpotatos, yay-bin, shelly-bin, localsend-bin, spore, brave-origin-bin, python-screeninfo, python-imageio-ffmpeg, waypaper.
4. **ISO:** `sudo ./build.sh`  
   Output: `out/Sweetpotatos_*.iso` (current default rename: `Sweetpotatos_2026.10_Third_Harvest.iso`).  
   Work dir: `work/` (cleared each ISO build).
5. **Smoke:** `./scripts/smoke-check.sh`
6. **Publish**
   - Git SweetPotato → GitHub.
   - Git SweetPotatOs → GitHub **and** `sourceforge`.
   - ISO only: `SF_USER=visnudeva SF_RELEASE=2026.10_Third_Harvest ./sourceforge/upload.sh`  
     (rsync ISO + `.sha256` + `htdocs/`). Then SF Files → set default download on the `.iso`.
   - **Point-release ISOs only** — do **not** reintroduce in-place `spo-upgrade` / overlay pacman channel. Theme on other distros: SweetPotato `install.sh`.

### `build.sh` flags

| Flag | Effect |
|------|--------|
| (none) | Build ISO (auto-builds missing `repo/` pkgs) |
| `--build-packages` | All local/AUR pkgs into `repo/` only |
| `--build-calamares` / `--build-swirl` / `--build-sweetpotatos` / `--build-aur-apps` | Subsets |

Run via `sudo ./build.sh` from a **normal user** (uses `SUDO_USER` for makepkg), not a root login shell.

### Release naming (current)

| Item | Value |
|------|--------|
| Marketing | Third Harvest |
| `iso_version` / folder | `2026.10_Third_Harvest` |
| ISO file | `Sweetpotatos_2026.10_Third_Harvest.iso` |
| Label | `SPOTATO_THIRD202610` |
| Prior | First `2026.08_…`, Second `2026.09_…` |

Bump together: `profile/profiledef.sh`, `build.sh` `SWEETPOTATOS_ISO_NAME` default, `sourceforge/upload.sh` defaults, changelog/htdocs.

### SourceForge

- Project: `sweetpotatos` — **ISO + project web only** (no pacman `repo/` tree in Files).
- Git: `ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code`
- Web: `sourceforge/htdocs/` → https://sweetpotatos.sourceforge.io/
- Setup checklist: `sourceforge/SETUP.md`
- Optional leftover overlay cleanup: `./sourceforge/remove-repo.sh`

---

## 3) Hard rules (never regress these)

### Theme / compositor

- Theme SoT = **SweetPotato**; ISO gets it only via `./sync-theme.sh` (not hand-copy one tree).
- Compositor = **Swirl**. Keep Arch `sway` for swaybar/swaymsg/swaynag only.
- User config: `~/.config/swirl/` **only** — never ship `~/.config/sway/` in skel (Swirl prefers sway path first). Keep `include /etc/sway/config.d/*`.
- Display layouts: nwg-displays + `~/.config/sway/outputs` created at runtime; launcher Exec = `sweetpotatos-displays` on PATH. Do not ship `~/.config/sway/` in skel.
- Default terminal = **foot** (opaque `alpha=1.0` under `[colors-dark]`). Do not ship kitty / switch Mod+Return without SweetPotato + sync.
- Default wallpaper = **SpoNeon.png**; no UsefulBinds/BindsBG. `ensure-wallpaper.sh` must not clobber a saved `wallpaper.conf`.
- Fastfetch primary logo = colored **`SPLogo.png`** via `logo.type: chafa`. Not sixel/`auto`/monochrome `.asc` as primary.

### Lid / caffeine / services

- Lid close → suspend: `lid-sleep.conf`. Never bring back `do-not-suspend.conf` (`HandleLidSwitch=ignore`).
- Caffeine = idle inhibit only; must **not** block lid suspend. Live ISO: caffeine **on by default**.
- Enable `bluetooth.service` + `power-profiles-daemon`. Do not enable sshd / ModemManager / VM guests by default.
- Ly: `default_input = password`; `waylandsessions` = Swirl only. Never ship `/etc/ly/save.txt` as `0` (root). Post-install `sweetpotatos-fix-ly` sets `${USER}`, drops `liveuser`.

### Install / sudo / cleanup

- `sweetpotatos-fix-sudo` (fix-ly + cleanup-live): add user to `wheel`, write `/etc/sudoers.d/10-installed-user` + `10-wheel`. Do not rely only on Calamares `10-installer`.
- `cleanup-live`: remove Install SweetPotatOs / calamares `.desktop` leftovers.
- Live Calamares keyboard: `sweetpotatos-sway-xkb-watch` (busctl poll locale1 → swaymsg). Not `dbus-monitor --system` as liveuser. Installed: `fix-sway-keyboard` (`config-us` / `config-fr`).
- Shellprocess GS vars must be `${gs[keyboardLayout]}` / `${gs[keyboardVariant]}` (bare `gs[...]` aborts install). Prefix failing tweaks with `-`.

### Packages / apps

- No Flatpak/Bazaar. Ship via local `repo/`: yay-bin, shelly-bin, localsend-bin, spore, brave-origin-bin, waypaper (+ deps), swirl, calamares, sweetpotatos.
- Default browser Mod+w = **Brave Origin**; Firefox not default (upgrades may keep Firefox but retarget bind).
- Music/radio = **Spore** (Mod+r); nearby share = LocalSend. (Older tera/Audacious stack retired.)
- shelly-bin / spore / brave-origin-bin / localsend-bin: local PKGBUILDs under `packaging/` (AUR Anubis / packaging gotchas).

### Publish policy

- Push SweetPotatOs to **both** `origin` and `sourceforge` when asked to publish git.
- ISO upload separate from git.
- Point releases only — no `spo-upgrade` overlay channel.

---

## 4) Live ISO behavior (quick reference)

| Item | Value |
|------|--------|
| User | `liveuser`, empty password, sudo NOPASSWD |
| Autologin | tty1 → Swirl (`sweetpotatos-session`) |
| Installer | Autostart ~5s, Mod+i, `sweetpotatos-calamares`, float window |
| Installed login | Ly on tty2; GRUB; squashfs unpack |
| Bar poll | `status.sh` every 3s |
| Tips | `tips.sh` → Mod+? cheatsheet every session |

Session / Ly: hide stock `sway.desktop` via pacman hook; swirl package provides session. `XDG_CURRENT_DESKTOP` forced to Swirl where needed.

---

## 5) Repo map (what lives where)

```text
SweetPotatOs/
├── AGENT_MEMORY_BACKUP.md   # this file
├── NOTES.md                 # shorter maintainer notes (keep in sync mentally)
├── .cursor/rules/project-notes.mdc  # always-on Cursor rules
├── build.sh / sync-theme.sh
├── run-container-build*.sh  # Bluefin/Fedora → Arch podman path
├── packaging/{swirl,sweetpotatos,shelly-bin,localsend-bin,spore,brave-origin-bin,…}
├── profile/                 # archiso profile + airootfs
├── repo/                    # local pacman pkgs (built artifacts)
├── out/                     # ISOs
├── scripts/smoke-check.sh
└── sourceforge/             # upload.sh, htdocs/, SETUP.md
```

Sibling: `SweetPotato/` — Swirl/gtk/fastfetch/wallpapers/`install.sh`.

---

## 6) Host-migration notes (Bluefin → Arch)

| On Bluefin (old) | On Arch (new) |
|------------------|---------------|
| `sudo ./run-container-build.sh` | Prefer `sudo ./build.sh` native |
| `sync-theme.sh` skips `$HOME` (GNOME) | May sync live home; still use `--iso-only` if only updating ISO trees |
| Paths under `/var/home/visnudeva/…` | Update `profile/pacman.conf` Server= after clone |
| Container `.container-build` cache | Optional; not required on native Arch |

Product goal unchanged: Arch-based live ISO with SweetPotato Swirl + Calamares for old/slow PCs.

---

## 7) “First message” prompt for a new Cursor session

Copy-paste after opening the repo on the new system:

```text
You are continuing SweetPotatOs work after a host reinstall.
Read AGENT_MEMORY_BACKUP.md, NOTES.md, and .cursor/rules/project-notes.mdc.
Repos are siblings: SweetPotatOs + SweetPotato. Theme SoT is SweetPotato; sync with ./sync-theme.sh.
We build point-release ISOs only (no spo-upgrade). Current release branding is Third Harvest (2026.10).
Do not regress: swirl-only ~/.config/swirl, foot terminal, chafa SPLogo.png, lid-sleep.conf, Ly/sudo post-install hooks, Brave Origin Mod+w.
```

---

## 8) Related URLs

- GitHub ISO: https://github.com/visnudeva/SweetPotatOs  
- GitHub theme: https://github.com/visnudeva/SweetPotato  
- Downloads: https://sourceforge.net/projects/sweetpotatos/files/  
- Project site: https://sweetpotatos.sourceforge.io/  
- Spore: https://github.com/visnudeva/spore  
