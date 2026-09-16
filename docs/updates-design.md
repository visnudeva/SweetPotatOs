# SweetPotatOs updates design (draft)

How we could ship **theme / Swirl / branding** updates to installed systems the
way Ryoku does, without inventing a second full distro or resurrecting
`spo-upgrade`. Inspired by [Ryoku-dev/ryoku-arch](https://github.com/Ryoku-dev/ryoku-arch)
`docs/updates.md` and the signed `[ryoku]` repo at https://repo.ryoku.dev/.

**Policy today:** point-release ISOs only; local `repo/` is for **ISO build**.
This doc is the path to an optional **installed-system** channel later.

## What Ryoku does (compressed)

| Idea | Ryoku |
|------|--------|
| Two lanes | `ryoku update` = only `[ryoku]` packages; `pacman -Syu` = Arch/kernel |
| Custom repo | Signed `[ryoku]` (`Server = https://repo.ryoku.dev/stable/$arch`) |
| Config | Package ships `/usr/share/ryoku/config` → `ryoku materialize` into `~/.config` |
| User intent | Overlay `~/.config/ryoku/user_edits/`; seed-only files never clobbered |
| Safety | Snapper pre/post, `ryoku rollback`, optional boot guard |
| Extra apps | Some (e.g. Ryotunes) via GitHub Releases + `pacman -U` |

Ryoku never mixes kernel upgrades into its own update command so rollbacks stay
meaningful and a stuck Arch mirror does not block a desktop fix.

## What we already have

| Piece | Today |
|-------|--------|
| Packages | `packaging/{swirl,sweetpotatos,…}` → `repo/` for archiso |
| Theme | Sibling **SweetPotato** → `sync-theme.sh` into ISO skel/liveuser |
| Installed box | No update channel; reinstall ISO or re-run SweetPotato `install.sh` |
| Hosting | SourceForge = **ISOs + project web only**; packages stay off SF Files |

## Mapping

| Ryoku | SweetPotatOs analogue |
|-------|------------------------|
| `[ryoku]` | Remote `[sweetpotatos]` (`swirl`, `sweetpotatos`, maybe theme pkg) |
| `/usr/share/ryoku/config` + materialize | `/usr/share/sweetpotato/` → `~/.config/swirl`, gtk, foot, … |
| `user_edits` | `~/.config/sweetpotatos/user_edits/` (or Swirl `config.d/user`) |
| `ryoku update` | Thin `sweetpotatos-update` / `spo` CLI |
| Point-release ISO | Keep as golden path for new installs |

## Hosting decision (do not put the pacman repo on SourceForge)

SF Files once had a `repo/` tree (overlay mirror). That was removed on purpose:
`NOTES.md` / `SETUP.md` keep SourceForge to **ISO downloads + project web**, and
`./sourceforge/remove-repo.sh` clears leftover `Files/repo/`. Re-adding a pacman
db there re-clutters the download page and mixes multi‑GB ISOs with frequent
package churn.

**Publish packages on GitHub instead** (Releases assets or a small static
`repo/x86_64/` via Pages / a `repo` release tag). Installed systems get:

```ini
[sweetpotatos]
SigLevel = Optional TrustAll
Server = https://github.com/visnudeva/SweetPotatOs/releases/download/…/
```

(Exact URL when the first package release is cut.)

## Recommended MVP (ranked #1)

1. **Publish** existing `repo/*.pkg.tar.zst` + `sweetpotatos.db` to **GitHub
   Releases** (not SourceForge Files).
2. **Installed systems** get `/etc/pacman.d/sweetpotatos.conf` with that
   `Server=` (Calamares / `sweetpotatos` package post_install).
3. **Split theme delivery:** ship pristine base in a package; stop treating
   skel-only copy as the only path for updates.
4. **`sweetpotatos-materialize`:** clobber shipped files, honour overlay,
   seed-only for kanshi/outputs/monitors.
5. **`sweetpotatos-update`:** `pacman -Sy` + upgrade SPO package set by name →
   materialize → remind that Arch `pacman -Syu` is separate (no kernel in this
   command).
6. Keep **point-release ISOs on SourceForge**; do **not** bring back overlay
   `spo-upgrade` or SF `Files/repo/`.

Skip for v1: testing channel, Snapper/boot-guard, Hub UI, doctor reconcilers.

## Alternatives

- **#2** Pacman packages only, no CLI — least code; weak `~/.config` story.
- **#3** Stay ISO-only — matches current NOTES; no ongoing desktop channel.

## Status

**MVP live:** GitHub release [`pacman-repo`](https://github.com/visnudeva/SweetPotatOs/releases/tag/pacman-repo)
holds the package set. Publish with `./scripts/publish-repo.sh`. The `sweetpotatos`
package (≥ 2026.10.2) installs `/etc/pacman.d/sweetpotatos.conf`,
`sweetpotatos-update`, and `sweetpotatos-materialize`.

**Still later:** signed keyring, theme-only package split, richer doctor/reconcile.
