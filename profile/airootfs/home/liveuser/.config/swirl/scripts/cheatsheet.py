#!/usr/bin/env python3
"""SweetPotatOs keybinds panel — same chrome as Settings / themer."""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import GLib

GLib.set_prgname("sweetpotato-cheatsheet")
from gi.repository import Gdk, Gtk, Pango  # noqa: E402

SCRIPTS = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS))
import spo_ui  # noqa: E402

ROOT = Path(os.environ.get("SPO_CONFIG_ROOT", Path.home() / ".config"))
SHEET = ROOT / "swirl" / "cheatsheet.txt"
TITLE = "SweetPotatOs — keybinds"
APP_ID = "sweetpotato-cheatsheet"

# Section headings in cheatsheet.txt (leading spaces stripped for match).
SECTIONS = {
    "Settings",
    "This page",
    "Apps",
    "Window / layout",
    "Workspaces / overview",
    "Displays / look",
    "System",
    "Screenshots / media keys",
    "Gestures",
    "Resize mode (after Mod+Shift+r)",
    "Customize",
    "Desktop / package updates",
    "sweetpotatos-pruning",
}


def parse_sheet(path: Path) -> list[tuple[str, str]]:
    """Return rows as (kind, text) where kind is title|section|muted|bind|text."""
    if not path.is_file():
        return [("text", f"Missing {path}")]
    rows: list[tuple[str, str]] = []
    for raw in path.read_text().splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped:
            rows.append(("blank", ""))
            continue
        if stripped.startswith("SweetPotatOs") or stripped.startswith("SweetPotato"):
            rows.append(("title", stripped))
            continue
        if stripped.startswith("Mod ="):
            rows.append(("muted", stripped))
            continue
        if stripped in SECTIONS or stripped.startswith("Resize mode"):
            rows.append(("section", stripped))
            continue
        # Bind lines: key column then spaces then description
        if stripped.startswith("Esc or Mod+q"):
            rows.append(("bind", "Esc or Mod+q\tClose this window"))
            continue
        if stripped.startswith(
            (
                "Mod",
                "Print",
                "XF86",
                "3-finger",
                "4-finger",
                "hjkl",
                "Enter",
                "Escape",
                "top-left",
                "drag ",
                "click",
            )
        ):
            parts = stripped.split(None, 1)
            if len(parts) == 2:
                rows.append(("bind", f"{parts[0]}\t{parts[1]}"))
            else:
                rows.append(("text", stripped))
            continue
        if stripped.startswith("sudo ") or stripped.startswith("sweetpotatos-"):
            rows.append(("accent", stripped))
            continue
        if stripped.startswith("Edit ") or stripped.startswith("(") or stripped.startswith("A notice") or stripped.startswith("After ") or stripped.startswith("Reset ") or stripped.startswith("Keeps ") or stripped.startswith("Run "):
            rows.append(("muted", stripped))
            continue
        rows.append(("text", stripped))
    return rows


class Cheatsheet(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        self.set_default_size(520, 640)
        self.set_resizable(True)
        self.set_app_paintable(True)
        self._bg = (0x1D / 255, 0x1F / 255, 0x21 / 255)
        self._css = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            self._css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )
        self._apply_css(spo_ui.theme_mode(ROOT))

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        outer.set_margin_top(14)
        outer.set_margin_bottom(14)
        outer.set_margin_start(14)
        outer.set_margin_end(14)
        self.add(outer)

        title = Gtk.Label(label=TITLE)
        title.set_name("title")
        title.set_xalign(0)
        outer.pack_start(title, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)
        outer.pack_start(scroll, True, True, 0)

        self.list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        scroll.add(self.list_box)
        self._fill_list()

        hint = Gtk.Label(label="Esc or Mod+q to close")
        hint.set_name("muted")
        hint.set_xalign(0)
        outer.pack_start(hint, False, False, 0)

        self.connect("key-press-event", self._on_key)

    def _fill_list(self):
        for child in self.list_box.get_children():
            self.list_box.remove(child)
        for kind, text in parse_sheet(SHEET):
            if kind == "blank":
                spacer = Gtk.Box()
                spacer.set_size_request(-1, 6)
                self.list_box.pack_start(spacer, False, False, 0)
                continue
            if kind == "title":
                continue  # window title already shows this
            if kind == "section":
                label = Gtk.Label(label=text)
                label.set_name("section")
                label.set_xalign(0)
                self.list_box.pack_start(label, False, False, 0)
                continue
            if kind == "bind":
                key, desc = text.split("\t", 1)
                row = Gtk.Box(spacing=12)
                k = Gtk.Label(label=key)
                k.set_name("bind-key")
                k.set_xalign(0)
                k.set_width_chars(22)
                k.set_ellipsize(Pango.EllipsizeMode.END)
                d = Gtk.Label(label=desc)
                d.set_name("bind-desc")
                d.set_xalign(0)
                d.set_line_wrap(True)
                d.set_hexpand(True)
                row.pack_start(k, False, False, 0)
                row.pack_start(d, True, True, 0)
                self.list_box.pack_start(row, False, False, 0)
                continue
            label = Gtk.Label(label=text)
            label.set_name("muted" if kind in ("muted", "accent") else "bind-desc")
            if kind == "accent":
                label.set_name("bind-key")
            label.set_xalign(0)
            label.set_line_wrap(True)
            self.list_box.pack_start(label, False, False, 0)
        self.list_box.show_all()

    def _on_key(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

    def do_draw(self, cr):
        spo_ui.paint_window_bg(
            cr,
            self._bg,
            self.get_allocated_width(),
            self.get_allocated_height(),
        )
        child = self.get_child()
        if child is not None:
            self.propagate_draw(child, cr)
        titlebar = self.get_titlebar()
        if titlebar is not None:
            self.propagate_draw(titlebar, cr)
        return False

    def _apply_css(self, mode):
        accent = spo_ui.accent_hex(ROOT)
        highlight = spo_ui.highlight_hex(ROOT)
        on_highlight = spo_ui.on_highlight_hex(ROOT)
        p = spo_ui.palette(mode, accent, highlight, on_highlight)
        self._bg = tuple(int(p["bg"][i : i + 2], 16) / 255 for i in (0, 2, 4))
        self._css.load_from_data(
            spo_ui.panel_css(mode, accent, highlight, on_highlight)
        )
        self.queue_draw()


def already_open() -> bool:
    try:
        out = subprocess.check_output(
            ["swaymsg", "-t", "get_tree"], text=True, stderr=subprocess.DEVNULL
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
    return f'"app_id": "{APP_ID}"' in out or f'"app_id":"{APP_ID}"' in out


def close_existing() -> None:
    subprocess.run(
        ["swaymsg", f'[app_id="{APP_ID}"] kill'],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def float_window():
    if shutil.which("swaymsg"):
        subprocess.run(
            [
                "swaymsg",
                f'[app_id="{APP_ID}"] floating enable, sticky enable, '
                "border pixel 2, resize set width 42 ppt height 80 ppt, "
                "move position center",
            ],
            check=False,
        )
    return False


def main():
    if already_open():
        close_existing()
        return
    if not SHEET.is_file():
        subprocess.run(
            [
                "notify-send",
                "-a",
                "SweetPotato",
                "-i",
                "help-about",
                "Cheatsheet",
                f"Missing {SHEET}",
            ],
            check=False,
        )
        sys.exit(1)
    win = Cheatsheet()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    GLib.timeout_add(150, float_window)
    Gtk.main()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"cheatsheet: {exc}", file=sys.stderr)
        subprocess.run(
            [
                "notify-send",
                "-a",
                "SweetPotato",
                "Keybinds",
                "The keybinds window could not open.",
            ],
            check=False,
        )
        sys.exit(1)
