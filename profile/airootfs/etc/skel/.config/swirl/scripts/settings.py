#!/usr/bin/env python3
"""SweetPotatOs Settings — desktop toggles and shortcuts to look/system tools."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import GLib

GLib.set_prgname("sweetpotato-settings")
from gi.repository import Gdk, Gtk  # noqa: E402

ROOT = Path(os.environ.get("SPO_CONFIG_ROOT", Path.home() / ".config"))
SCRIPTS = Path(__file__).resolve().parent
THEME = ROOT / "sweetpotatos" / "theme"
FRAME = ROOT / "sweetpotatos" / "frame"
SMART = ROOT / "sweetpotatos" / "smart-brightness" / "enabled"
HOT_CORNER = ROOT / "sweetpotatos" / "hot-corner"
CAFFEINE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "sweetpotato-caffeine.state"
TITLE = "SweetPotatOs Settings"


def theme_mode():
    if THEME.is_file():
        for line in THEME.read_text().splitlines():
            if line.startswith("mode="):
                return line.split("=", 1)[1].strip() or "dark"
            if line.startswith("id=") and "light" in line.split("=", 1)[1]:
                return "light"
    return "dark"


def frames_on():
    if FRAME.is_file() and FRAME.read_text().strip() == "off":
        return False
    return True


def smart_on():
    if SMART.is_file() and SMART.read_text().strip() == "off":
        return False
    return True


def caffeine_on():
    return CAFFEINE.is_file() and CAFFEINE.read_text().strip() == "on"


def hot_corner_on():
    if HOT_CORNER.is_file() and HOT_CORNER.read_text().strip() == "off":
        return False
    return True


def run_script(name, *args):
    path = SCRIPTS / name
    if not path.is_file():
        return
    subprocess.Popen([str(path), *args], start_new_session=True)


def spawn(*argv):
    if not argv:
        return
    if shutil.which(argv[0]) is None and not Path(argv[0]).is_file():
        subprocess.run(
            [
                "notify-send",
                "-a",
                "SweetPotato",
                "Settings",
                f"{argv[0]} is not installed.",
            ],
            check=False,
        )
        return
    subprocess.Popen(argv, start_new_session=True)


def open_wallpaper(*_args):
    # Same binary Mod+Ctrl+w uses. Prefer absolute paths so a thin
    # compositor PATH still finds the package install.
    for candidate in (
        shutil.which("waypaper"),
        "/usr/bin/waypaper",
        "/usr/local/bin/waypaper",
    ):
        if candidate and Path(candidate).is_file():
            spawn(candidate)
            return
    subprocess.run(
        [
            "notify-send",
            "-a",
            "SweetPotatOs",
            TITLE,
            "waypaper is not installed.",
        ],
        check=False,
    )


def open_updates(*_args):
    term = shutil.which("foot") or shutil.which("xterm") or "foot"
    spawn(
        term,
        "-a",
        "sweetpotato-settings-term",
        "-e",
        "bash",
        "-lc",
        'sudo sweetpotatos-update; echo; read -n1 -rsp "Press any key to close…" || true',
    )


class Settings(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        self.set_default_size(420, -1)
        self.set_resizable(False)
        self.set_app_paintable(True)
        self._bg = (0x1D / 255, 0x1F / 255, 0x21 / 255)
        self._css = Gtk.CssProvider()
        self._setting = False
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            self._css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )
        self._apply_css(theme_mode())

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)
        self.add(box)

        title = Gtk.Label(label=TITLE)
        title.set_name("title")
        title.set_xalign(0)
        box.pack_start(title, False, False, 0)

        box.pack_start(self._heading("Look"), False, False, 0)
        look = Gtk.Box(spacing=8)
        look.set_homogeneous(True)
        look.pack_start(self._button("Themer", self._open_themer), True, True, 0)
        look.pack_start(self._button("Wallpaper", open_wallpaper), True, True, 0)
        look.pack_start(self._button("Laniakea", lambda *_: spawn("laniakea")), True, True, 0)
        box.pack_start(look, False, False, 0)

        box.pack_start(self._heading("Desktop"), False, False, 0)
        self.sw_frames = self._switch_row(box, "Corners and gaps", self._on_frames)
        self.sw_hot = self._switch_row(box, "Overview hot corner", self._on_hot_corner)
        self.sw_smart = self._switch_row(box, "Smart Brightness", self._on_smart)
        self.sw_caffeine = self._switch_row(box, "Caffeine", self._on_caffeine)

        box.pack_start(self._heading("System"), False, False, 0)
        row1 = Gtk.Box(spacing=8)
        row1.set_homogeneous(True)
        row1.pack_start(
            self._button("Displays", lambda *_: run_script("nwg-displays.sh")),
            True,
            True,
            0,
        )
        row1.pack_start(
            self._button("Sound", lambda *_: spawn("pavucontrol")), True, True, 0
        )
        row1.pack_start(
            self._button("Network", lambda *_: spawn("networkmanager_dmenu")),
            True,
            True,
            0,
        )
        box.pack_start(row1, False, False, 0)

        row2 = Gtk.Box(spacing=8)
        row2.set_homogeneous(True)
        row2.pack_start(
            self._button("Bluetooth", lambda *_: spawn("blueman-manager")),
            True,
            True,
            0,
        )
        if shutil.which("nwg-look"):
            row2.pack_start(
                self._button("GTK look", lambda *_: spawn("nwg-look")), True, True, 0
            )
        row2.pack_start(
            self._button("Keybinds", lambda *_: run_script("cheatsheet.sh")),
            True,
            True,
            0,
        )
        row2.pack_start(self._button("Updates", open_updates), True, True, 0)
        box.pack_start(row2, False, False, 0)

        self.connect("key-press-event", self._on_key)
        self.refresh()
        GLib.timeout_add(1000, self._tick)

    def _heading(self, text):
        label = Gtk.Label(label=text)
        label.set_name("section")
        label.set_xalign(0)
        return label

    def _button(self, label, handler):
        button = Gtk.Button.new_with_label(label)
        button.connect("clicked", handler)
        return button

    def _switch_row(self, parent, label, handler):
        row = Gtk.Box(spacing=8)
        text = Gtk.Label(label=label)
        text.set_xalign(0)
        text.set_hexpand(True)
        switch = Gtk.Switch()
        switch.connect("notify::active", handler)
        row.pack_start(text, True, True, 0)
        row.pack_start(switch, False, False, 0)
        parent.pack_start(row, False, False, 0)
        return switch

    def _on_key(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

    def do_draw(self, cr):
        red, green, blue = self._bg
        cr.set_source_rgb(red, green, blue)
        cr.rectangle(0, 0, self.get_allocated_width(), self.get_allocated_height())
        cr.fill()
        child = self.get_child()
        if child is not None:
            self.propagate_draw(child, cr)
        titlebar = self.get_titlebar()
        if titlebar is not None:
            self.propagate_draw(titlebar, cr)
        return False

    def _apply_css(self, mode):
        if mode == "light":
            bg, fg = "f4f1ec", "241e20"
            raised, hover, border = "e8e2d8", "e0d9cf", "d4cdc2"
        else:
            bg, fg = "1d1f21", "f5e6e8"
            raised, hover, border = "222426", "2c3032", "2e3234"
        self._bg = tuple(int(bg[i : i + 2], 16) / 255 for i in (0, 2, 4))
        self._css.load_from_data(
            f"""
            window, decoration.background, .background {{
              background-color: #{bg};
              color: #{fg};
            }}
            label {{ color: #{fg}; }}
            #title {{ color: #{fg}; font-weight: bold; font-size: 14pt; }}
            #section {{ color: #{fg}; font-weight: bold; margin-top: 4px; }}
            button {{
              background-image: none;
              background-color: #{raised};
              color: #{fg};
              border-color: #{border};
            }}
            button:hover {{
              background-color: #{hover};
              color: #{fg};
            }}
            switch {{
              background-color: #{raised};
              border-color: #{border};
            }}
            switch:checked {{
              background-color: #a73b50;
              border-color: #a73b50;
            }}
            """.encode()
        )
        self.queue_draw()

    def _set_switch(self, switch, active):
        self._setting = True
        switch.set_active(active)
        self._setting = False

    def refresh(self):
        self._set_switch(self.sw_frames, frames_on())
        self._set_switch(self.sw_hot, hot_corner_on())
        self._set_switch(self.sw_smart, smart_on())
        self._set_switch(self.sw_caffeine, caffeine_on())
        self._apply_css(theme_mode())

    def _tick(self):
        if self.get_realized():
            self.refresh()
            return True
        return False

    def _open_themer(self, *_args):
        hues = shutil.which("sweetpotatos-hues")
        if hues:
            spawn(hues)
        else:
            run_script("theme.sh", "hue")

    def _on_frames(self, switch, _pspec):
        if self._setting:
            return
        run_script("frame.sh", "on" if switch.get_active() else "off")

    def _on_hot_corner(self, switch, _pspec):
        if self._setting:
            return
        run_script("hot-corner.sh", "on" if switch.get_active() else "off")

    def _on_smart(self, switch, _pspec):
        if self._setting:
            return
        run_script("smart-brightness.sh", "on" if switch.get_active() else "off")

    def _on_caffeine(self, switch, _pspec):
        if self._setting:
            return
        run_script("caffeine.sh", "on" if switch.get_active() else "off")


def float_window():
    if shutil.which("swaymsg"):
        subprocess.run(
            ["swaymsg", '[app_id="sweetpotato-settings"] floating enable'],
            check=False,
        )
    return False


def main():
    win = Settings()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    GLib.timeout_add(150, float_window)
    Gtk.main()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"settings: {exc}", file=sys.stderr)
        subprocess.run(
            [
                "notify-send",
                "-a",
                "SweetPotatOs",
                TITLE,
                "The settings window could not open.",
            ],
            check=False,
        )
        sys.exit(1)
