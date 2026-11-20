# renewm lab lane (not a channel app yet)

**renewm** / **repywm** are an experimental second Wayland session for studying
newm’s wall concept. They are **not** in the default `sweetpotatos-update`
candidate list and are **not** bumped by `scripts/bump-channel-apps.sh`.

## On a SweetPotatOs machine

```sh
sweetpotatos-update --renewm          # pull + build + Ly session
sweetpotatos-renewm --check           # status
```

That only touches `~/code/GITHUB/renewm`, `~/code/GITHUB/repywm`, the
user renewm venv, and `/etc/ly/wayland-sessions/renewm.desktop`.
Swirl and the desktop package set are left alone.

## Maintainer note

When (if) renewm graduates to a pacman package on the channel, add a PKGBUILD
here and wire a **separate** opt-in list — still keep it out of the default
`CANDIDATES` array unless product wants every install to get it.
