# Swirl wall-mode lab lane

Builds the **wall-mode** Swirl branch (newm-style 2D tile grid + zoom) and
syncs SweetPotato Settings/keybinds. Opt-in only — not part of the default
`sweetpotatos-update` candidate list.

## On a SweetPotatOs machine

```sh
sweetpotatos-update --wall          # pull + build Swirl + desktop bits
sweetpotatos-wall --check           # status
sweetpotatos-wall --desktop-only    # config/scripts only
sweetpotatos-wall --remove          # back to packaged Swirl (clean)
```

`--remove` turns wall off, strips wall binds/`exec_always` from
`~/.config/swirl/config`, deletes `wall-mode.sh` + state, restores Settings so
the Wall toggle is gone (it only appears while the lab helper is installed),
scrubs cheatsheet wall lines, force-reinstalls the channel `swirl` package over
the meson binary, and drops `build-wall`. Then log out and back in.

Touches (while installed):

- `~/code/GITHUB/swirl` on branch `wall-mode-v1` (override with
  `SWEETPOTATOS_WALL_BRANCH` / `SWEETPOTATOS_SWIRL_URL`)
- `~/code/GITHUB/SweetPotato` (wall scripts + Settings)
- `/usr/bin/swirl` (meson install over the packaged binary)
- `~/.config/swirl` wall bits (`wall-mode.sh`, Settings, binds)

Log out once after a compositor rebuild. A later packaged `swirl` upgrade may
overwrite the binary — re-run `--wall`.

## Between machines

1. Commit + push `wall-mode-v1` on swirl (and SweetPotato desktop bits on
   `main` if needed).
2. On the other box: `sweetpotatos-update --wall`.
