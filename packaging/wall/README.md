# Swirl wall-mode lab lane

Builds the **wall-mode** Swirl branch (free 2D pan) and syncs SweetPotato
Settings/keybinds. Opt-in only — not part of the default
`sweetpotatos-update` candidate list.

## On a SweetPotatOs machine

```sh
sweetpotatos-update --wall          # pull + build Swirl + desktop bits
sweetpotatos-wall --check           # status
sweetpotatos-wall --desktop-only    # config/scripts only
```

Touches:

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
