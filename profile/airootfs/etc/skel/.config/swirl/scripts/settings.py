#!/usr/bin/env python3
"""SweetPotatOs Settings — sectioned hub over existing desktop tools.

Pages: look (embedded themer), desktop, system, apps (Spore/tuber),
help (embedded keybinds).
Deep-link: sweetpotatos-settings open look|desktop|system|apps|help
Toggles stay wrappers around the owning scripts — do not fork state.
"""
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

GLib.set_prgname("sweetpotato-settings")
from gi.repository import Gdk, Gtk  # noqa: E402

SCRIPTS = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS))
import cheatsheet as spo_cheatsheet  # noqa: E402
import hue as spo_hue  # noqa: E402
import spo_ui  # noqa: E402
import system_panel as spo_system  # noqa: E402

ROOT = Path(os.environ.get("SPO_CONFIG_ROOT", Path.home() / ".config"))
FRAME = ROOT / "sweetpotatos" / "frame"
SMART = ROOT / "sweetpotatos" / "smart-brightness" / "enabled"
HOT_CORNER = ROOT / "sweetpotatos" / "hot-corner"
WALL_MODE = ROOT / "sweetpotatos" / "wall-mode"
LOGIN_TIP = ROOT / "sweetpotatos" / "login-tip"
PAGE_FILE = ROOT / "sweetpotatos" / "settings-page"
CAFFEINE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "sweetpotato-caffeine.state"
TITLE = "SweetPotatOs Settings"
SITE_URL = "https://sweetpotatos.sourceforge.io/"

PAGES = (
    ("look", "Look"),
    ("desktop", "Desktop"),
    ("system", "System"),
    ("apps", "SPO Apps"),
    ("help", "Help"),
)
PAGE_KEYS = {key for key, _ in PAGES}
PAGE_ALIASES = {"updates": "help"}  # older deep-links / remembered page
DEFAULT_PAGE = "look"


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


def open_at_login_on():
    """Default on. login-tip=off disables the once-per-login Settings open."""
    if LOGIN_TIP.is_file() and LOGIN_TIP.read_text().strip() == "off":
        return False
    return True


def set_open_at_login(enabled: bool) -> None:
    LOGIN_TIP.parent.mkdir(parents=True, exist_ok=True)
    LOGIN_TIP.write_text("on\n" if enabled else "off\n")


def normalize_page(key: str | None) -> str:
    if not key:
        return DEFAULT_PAGE
    key = key.strip().lower()
    key = PAGE_ALIASES.get(key, key)
    return key if key in PAGE_KEYS else DEFAULT_PAGE


def load_last_page() -> str:
    if PAGE_FILE.is_file():
        return normalize_page(PAGE_FILE.read_text().strip())
    return DEFAULT_PAGE


def save_last_page(key: str) -> None:
    key = normalize_page(key)
    PAGE_FILE.parent.mkdir(parents=True, exist_ok=True)
    PAGE_FILE.write_text(f"{key}\n")


def parse_page_arg(argv: list[str]) -> str | None:
    """Return a page key from argv, or None for the remembered/default page."""
    args = list(argv)
    if not args:
        return None
    if args[0] in ("-h", "--help"):
        print(
            "Usage: sweetpotatos-settings [open] <page>\n"
            "Pages: " + ", ".join(key for key, _ in PAGES),
            file=sys.stderr,
        )
        sys.exit(0)
    if args[0] == "open":
        args = args[1:]
    if not args:
        return None
    key = normalize_page(args[0])
    # Reject unknown before alias-normalization ate them into default
    raw = args[0].strip().lower()
    if raw not in PAGE_KEYS and raw not in PAGE_ALIASES:
        print(
            f"settings: unknown page {args[0]!r} "
            f"(try: {', '.join(k for k, _ in PAGES)})",
            file=sys.stderr,
        )
        sys.exit(2)
    return key


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


def open_spore(*_args):
    term = shutil.which("foot") or shutil.which("xterm") or "foot"
    spawn(term, "-e", "spore")


def open_tuber(*_args):
    if shutil.which("tuber-open"):
        spawn("tuber-open")
        return
    term = shutil.which("foot") or shutil.which("xterm") or "foot"
    spawn(term, "-e", "tuber")


class Settings(Gtk.Window):
    def __init__(self, initial_page: str | None = None):
        super().__init__(title=TITLE)
        self.set_default_size(720, 560)
        self.set_resizable(True)
        self.set_app_paintable(True)
        self._bg = (0x1D / 255, 0x1F / 255, 0x21 / 255)
        self._css = Gtk.CssProvider()
        self._setting = False
        self._page = normalize_page(initial_page) if initial_page else load_last_page()
        self._page_title = None
        self._stack = None
        self._rail = None
        self._rail_rows = {}
        self._themer = None
        self._system = None
        self._cheatsheet = None
        self.sw_frames = None
        self.sw_hot = None
        self.sw_wall = None
        self.sw_smart = None
        self.sw_caffeine = None
        self.sw_login = None

        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            self._css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )
        self._apply_css(spo_ui.theme_mode(ROOT))
        self._build()
        self.connect("key-press-event", self._on_key)
        # Gtk.Stack drops set_visible_child before realize/show_all; re-apply on map.
        self.connect("map-event", self._on_map)
        self.show_page(self._page, persist=False)
        self.refresh()
        GLib.timeout_add(1000, self._tick)

    def _build(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        outer.set_margin_top(16)
        outer.set_margin_bottom(16)
        outer.set_margin_start(16)
        outer.set_margin_end(16)
        self.add(outer)

        title = Gtk.Label(label=TITLE)
        title.set_name("title")
        title.set_xalign(0)
        outer.pack_start(title, False, False, 0)

        body = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        body.set_margin_top(12)
        outer.pack_start(body, True, True, 0)

        self._rail = Gtk.ListBox()
        self._rail.set_name("hub-rail")
        self._rail.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self._rail.set_size_request(120, -1)
        self._rail.set_valign(Gtk.Align.START)
        for key, label in PAGES:
            row = Gtk.ListBoxRow()
            row._spo_page = key  # noqa: SLF001
            text = Gtk.Label(label=label)
            text.set_xalign(0)
            text.set_margin_start(8)
            text.set_margin_end(8)
            text.set_margin_top(6)
            text.set_margin_bottom(6)
            row.add(text)
            self._rail.add(row)
            self._rail_rows[key] = row
        self._rail.connect("row-selected", self._on_rail_selected)
        body.pack_start(self._rail, False, False, 0)

        page_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        page_col.set_hexpand(True)
        body.pack_start(page_col, True, True, 0)

        self._page_title = Gtk.Label(label="")
        self._page_title.set_name("hub-page-title")
        self._page_title.set_xalign(0)
        page_col.pack_start(self._page_title, False, False, 0)

        self._stack = Gtk.Stack()
        self._stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self._stack.set_transition_duration(120)
        self._stack.set_hexpand(True)
        self._stack.set_vexpand(True)
        page_col.pack_start(self._stack, True, True, 0)

        self._stack.add_named(self._build_look(), "look")
        self._stack.add_named(self._build_desktop(), "desktop")
        self._stack.add_named(self._build_system(), "system")
        self._stack.add_named(self._build_apps(), "apps")
        self._stack.add_named(self._build_help(), "help")

    def _page_box(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_valign(Gtk.Align.FILL)
        box.set_vexpand(True)
        return box

    def _build_look(self):
        box = self._page_box()
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)
        box.pack_start(scroll, True, True, 0)

        inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        # Clearance so slider swatches are not covered by the vertical scrollbar.
        inner.set_margin_end(14)
        scroll.add(inner)

        self._themer = spo_hue.ThemerPanel(
            on_applied=self._on_themer_applied,
            show_title=False,
        )
        inner.pack_start(self._themer, False, False, 0)

        # Wallpaper / Laniakea stay external apps for now (waypaper; Laniakea is GTK4).
        extras = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        label = Gtk.Label(label="Wallpaper")
        label.set_name("section")
        label.set_xalign(0)
        extras.pack_start(label, False, False, 0)
        muted = Gtk.Label(
            label="Waypaper picks a wallpaper; Laniakea generates one."
        )
        muted.set_name("muted")
        muted.set_xalign(0)
        muted.set_line_wrap(True)
        extras.pack_start(muted, False, False, 0)
        self._button_grid(
            extras,
            [
                ("Waypaper", open_wallpaper),
                ("Laniakea", lambda *_: spawn("laniakea")),
            ],
            columns=2,
        )
        inner.pack_start(extras, False, False, 0)
        return box

    def _build_desktop(self):
        box = self._page_box()
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content.set_valign(Gtk.Align.START)
        muted = Gtk.Label(label="Compositor and session toggles.")
        muted.set_name("muted")
        muted.set_xalign(0)
        content.pack_start(muted, False, False, 0)
        self.sw_frames = self._switch_row(content, "Corners and gaps", self._on_frames)
        self.sw_hot = self._switch_row(
            content, "Overview hot corner", self._on_hot_corner
        )
        if wall_lab_available():
            self.sw_wall = self._switch_row(
                content, "Wall (2D grid + zoom)", self._on_wall_mode
            )
        self.sw_smart = self._switch_row(content, "Smart Brightness", self._on_smart)
        self.sw_caffeine = self._switch_row(content, "Caffeine", self._on_caffeine)
        self.sw_login = self._switch_row(
            content, "Open Settings at login", self._on_open_at_login
        )
        box.pack_start(content, True, True, 0)
        return box

    def _build_system(self):
        box = self._page_box()
        self._system = spo_system.SystemPanel(
            on_displays=lambda *_: run_script("nwg-displays.sh"),
            on_sound_adv=lambda *_: spawn("pavucontrol"),
            on_wifi_adv=lambda *_: spawn("networkmanager_dmenu"),
            on_bt_adv=lambda *_: spawn("blueman-manager"),
        )
        box.pack_start(self._system, True, True, 0)
        return box

    def _build_apps(self):
        box = self._page_box()
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        content.set_valign(Gtk.Align.START)

        intro = Gtk.Label(label="First-party SweetPotatOs apps.")
        intro.set_name("muted")
        intro.set_xalign(0)
        content.pack_start(intro, False, False, 0)

        spore_title = Gtk.Label(label="Spore")
        spore_title.set_name("section")
        spore_title.set_xalign(0)
        content.pack_start(spore_title, False, False, 0)
        spore_desc = Gtk.Label(
            label="TUI web radio and local music player (Mod+r)."
        )
        spore_desc.set_name("muted")
        spore_desc.set_xalign(0)
        spore_desc.set_line_wrap(True)
        content.pack_start(spore_desc, False, False, 0)
        content.pack_start(self._button("Open Spore", open_spore), False, False, 0)

        tuber_title = Gtk.Label(label="tuber")
        tuber_title.set_name("section")
        tuber_title.set_xalign(0)
        content.pack_start(tuber_title, False, False, 0)
        tuber_desc = Gtk.Label(
            label="TUI BitTorrent client for magnets and .torrent files (Mod+t)."
        )
        tuber_desc.set_name("muted")
        tuber_desc.set_xalign(0)
        tuber_desc.set_line_wrap(True)
        content.pack_start(tuber_desc, False, False, 0)
        content.pack_start(self._button("Open tuber", open_tuber), False, False, 0)

        box.pack_start(content, True, True, 0)
        return box

    def _build_help(self):
        box = self._page_box()
        self._cheatsheet = spo_cheatsheet.CheatsheetPanel(show_close_hint=False)
        box.pack_start(self._cheatsheet, True, True, 0)

        actions = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        label = Gtk.Label(label="Project")
        label.set_name("section")
        label.set_xalign(0)
        actions.pack_start(label, False, False, 0)
        help_grid = self._button_grid(
            actions,
            [
                ("Update", open_updates),
                ("Website", open_website),
            ],
            columns=2,
        )
        for child in help_grid.get_children():
            if isinstance(child, Gtk.Button) and child.get_label() == "Update":
                child.get_style_context().add_class("spo-update")
                break
        box.pack_start(actions, False, False, 0)
        return box

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
        switch.set_valign(Gtk.Align.CENTER)
        switch.connect("notify::active", handler)
        row.pack_start(text, True, True, 0)
        row.pack_start(switch, False, False, 0)
        parent.pack_start(row, False, False, 0)
        return switch

    def show_page(self, key: str, persist: bool = True):
        key = normalize_page(key)
        self._page = key
        label = next(name for k, name in PAGES if k == key)
        self._page_title.set_text(label)
        self._stack.set_visible_child_name(key)
        row = self._rail_rows.get(key)
        if row is not None and self._rail.get_selected_row() is not row:
            self._setting = True
            try:
                self._rail.select_row(row)
            finally:
                self._setting = False
        if key == "system" and self._system is not None:
            self._system.refresh_active()
        if key == "help" and self._cheatsheet is not None:
            self._cheatsheet.reload()
        if persist:
            save_last_page(key)

    def _on_rail_selected(self, _listbox, row):
        if self._setting or row is None:
            return
        key = getattr(row, "_spo_page", None)
        if key and key != self._page:
            self.show_page(key)

    def _on_map(self, _widget, _event):
        # Re-apply after realize/show_all so stack content matches the rail.
        self.show_page(self._page, persist=False)
        return False

    def _on_themer_applied(self, mode: str) -> None:
        self._apply_css(mode)
        self.refresh()

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
        if self._themer is not None:
            self._themer.set_ring_color(p["fg"])
        self._css.load_from_data(
            spo_ui.panel_css(mode, accent, highlight, on_highlight)
        )
        self.queue_draw()

    def _set_switch(self, switch, active):
        if switch is None:
            return
        self._setting = True
        switch.set_active(active)
        self._setting = False

    def refresh(self):
        self._set_switch(self.sw_frames, frames_on())
        self._set_switch(self.sw_hot, hot_corner_on())
        if self.sw_wall is not None:
            self._set_switch(self.sw_wall, wall_mode_on())
        self._set_switch(self.sw_smart, smart_on())
        self._set_switch(self.sw_caffeine, caffeine_on())
        self._set_switch(self.sw_login, open_at_login_on())
        self._apply_css(spo_ui.theme_mode(ROOT))

    def _tick(self):
        if self.get_realized():
            self.refresh()
            return True
        return False

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


def main(argv: list[str] | None = None):
    page = parse_page_arg(list(argv if argv is not None else sys.argv[1:]))
    win = Settings(initial_page=page)
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
