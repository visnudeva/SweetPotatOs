# Laniakea

Generative flow-field wallpaper for **SweetPotatOs** (Swirl / Wayland).

Open the app, watch a new pattern draw live, pick a shape mask, then **Apply wallpaper** to save a PNG and set it with swaybg / waypaper. Opt-in — it does not replace the default Neon wallpaper unless you apply one.

This is the desktop app sibling of the [GNOME Shell extension](https://github.com/visnudeva/Laniakea). Same particle sketch and masks; no GNOME Shell required.

## Features

- Live p5.js particle field (vendored — works offline)
- Shape masks: circle, triangles, diamond, hexagon, rectangles, wide
- Click inside the mask to redraw
- Save PNG or apply as the Swirl wallpaper (`~/Pictures/Wallpapers/laniakea.png`)

## Run (dev)

```bash
python -m laniakea
```

Needs `python-gobject`, `gtk4`, `libadwaita`, `webkitgtk-6.0`.

## Install on SweetPotatOs (testing channel)

```bash
sudo sweetpotatos-update --testing
# then open Laniakea from the app menu, or:
laniakea
```

## License

GNU General Public License v3.0 or later.
