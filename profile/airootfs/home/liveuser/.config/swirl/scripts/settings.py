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

SCRIPTS = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS))
import spo_ui  # noqa: E402

ROOT = Path(os.environ.get("SPO_CONFIG_ROOT", Path.home() / ".config"))
FRAME = ROOT / "sweetpotatos" / "frame"
SMART = ROOT / "sweetpotatos" / "smart-brightness" / "enabled"
HOT_CORNER = ROOT / "sweetpotatos" / "hot-corner"
WALL_MODE = ROOT / "sweetpotatos" / "wall-mode"
TRAY_MODE = ROOT / "sweetpotatos" / "tray-mode"
STATUS_DETAIL = ROOT / "sweetpotatos" / "status-detail"
LOGIN_TIP = ROOT / "sweetpotatos" / "login-tip"
CAFFEINE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "sweetpotato-caffeine.state"
TITLE = "SweetPotatOs Settings"
SITE_URL = "https://sweetpotatos.sourceforge.io/"


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


def wall_mode_on():
    return WALL_MODE.is_file() and WALL_MODE.read_text().strip() == "on"


def wall_lab_available():
    """Show Wall only while the wall lab is opted in (sweetpotatos-update --wall)."""
    marker = ROOT / "sweetpotatos" / "wall-lab"
    return marker.is_file() and (SCRIPTS / "wall-mode.sh").is_file()


def light_tray_on():
    return TRAY_MODE.is_file() and TRAY_MODE.read_text().strip() == "text"


def status_detail_on():
    return STATUS_DETAIL.is_file() and STATUS_DETAIL.read_text().strip() == "on"


def open_at_login_on():
    """Default on. login-tip=off disables the once-per-login Settings open."""
    if LOGIN_TIP.is_file() and LOGIN_TIP.read_text().strip() == "off":
        return False
    return True


def set_open_at_login(enabled: bool) -> None:
    LOGIN_TIP.parent.mkdir(parents=True, exist_ok=True)
    LOGIN_TIP.write_text("on\n" if enabled else "off\n")


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


def open_website(*_args):
    subprocess.Popen(
        ["xdg-open", SITE_URL],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


class Settings(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        self.set_default_size(440, -1)
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
        self._apply_css(spo_ui.theme_mode(ROOT))

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
        self._button_grid(
            box,
            [
                ("Themer", self._open_themer),
                ("Wallpaper", open_wallpaper),
                ("Laniakea", lambda *_: spawn("laniakea")),
            ],
            columns=3,
        )

        box.pack_start(self._heading("Desktop"), False, False, 0)
        self.sw_frames = self._switch_row(box, "Corners and gaps", self._on_frames)
        self.sw_hot = self._switch_row(box, "Overview hot corner", self._on_hot_corner)
        self.sw_wall = None
        if wall_lab_available():
            self.sw_wall = self._switch_row(
                box, "Wall (2D grid + zoom)", self._on_wall_mode
            )
        self.sw_detail = self._switch_row(
            box, "Detailed status bar", self._on_status_detail
        )
        self.sw_tray = self._switch_row(
            box, "Light tray (text only)", self._on_light_tray
        )
        self.sw_smart = self._switch_row(box, "Smart Brightness", self._on_smart)
        self.sw_caffeine = self._switch_row(box, "Caffeine", self._on_caffeine)

        box.pack_start(self._heading("System"), False, False, 0)
        self._button_grid(
            box,
            [
                ("Displays", lambda *_: run_script("nwg-displays.sh")),
                ("Sound", lambda *_: spawn("pavucontrol")),
                ("Network", lambda *_: spawn("networkmanager_dmenu")),
                ("Bluetooth", lambda *_: spawn("blueman-manager")),
            ],
            columns=2,
        )

        box.pack_start(self._heading("Help"), False, False, 0)
        help_grid = self._button_grid(
            box,
            [
                ("Keybinds", lambda *_: run_script("cheatsheet.sh")),
                ("Website", open_website),
                ("Update", open_updates),
            ],
            columns=3,
        )
        # Orange highlight — reads as the action to run an update.
        for child in help_grid.get_children():
            if isinstance(child, Gtk.Button) and child.get_label() == "Update":
                child.get_style_context().add_class("spo-update")
                break

        box.pack_start(self._heading("Startup"), False, False, 0)
        self.sw_login = self._switch_row(
            box, "Open Settings at login", self._on_open_at_login
        )

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
        button.set_hexpand(True)
        button.connect("clicked", handler)
        return button

    def _button_grid(self, parent, items, columns=2):
        grid = Gtk.Grid()
        grid.set_column_homogeneous(True)
        grid.set_column_spacing(8)
        grid.set_row_spacing(6)
        grid.set_hexpand(True)
        for index, (label, handler) in enumerate(items):
            grid.attach(
                self._button(label, handler),
                index % columns,
                index // columns,
                1,
                1,
            )
        parent.pack_start(grid, False, False, 0)
        return grid

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

    def _set_switch(self, switch, active):
        self._setting = True
        switch.set_active(active)
        self._setting = False

    def refresh(self):
        self._set_switch(self.sw_frames, frames_on())
        self._set_switch(self.sw_hot, hot_corner_on())
        if self.sw_wall is not None:
            self._set_switch(self.sw_wall, wall_mode_on())
        self._set_switch(self.sw_detail, status_detail_on())
        self._set_switch(self.sw_tray, light_tray_on())
        self._set_switch(self.sw_smart, smart_on())
        self._set_switch(self.sw_caffeine, caffeine_on())
        self._set_switch(self.sw_login, open_at_login_on())
        self._apply_css(spo_ui.theme_mode(ROOT))

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

    def _on_wall_mode(self, switch, _pspec):
        if self._setting:
            return
        run_script("wall-mode.sh", "on" if switch.get_active() else "off")

    def _on_status_detail(self, switch, _pspec):
        if self._setting:
            return
        run_script("status-detail.sh", "on" if switch.get_active() else "off")

    def _on_light_tray(self, switch, _pspec):
        if self._setting:
            return
        run_script("tray-mode.sh", "text" if switch.get_active() else "icons")

    def _on_smart(self, switch, _pspec):
        if self._setting:
            return
        run_script("smart-brightness.sh", "on" if switch.get_active() else "off")

    def _on_caffeine(self, switch, _pspec):
        if self._setting:
            return
        run_script("caffeine.sh", "on" if switch.get_active() else "off")

    def _on_open_at_login(self, switch, _pspec):
        if self._setting:
            return
        set_open_at_login(switch.get_active())


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
