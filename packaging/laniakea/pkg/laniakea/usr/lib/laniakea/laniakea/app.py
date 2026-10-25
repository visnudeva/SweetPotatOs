# SPDX-License-Identifier: GPL-3.0-or-later
from __future__ import annotations

import base64
import os
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("WebKit", "6.0")
gi.require_version("Pango", "1.0")

from gi.repository import Adw, Gio, GLib, Gtk, Pango, WebKit

from laniakea.config import (
    MASK_MODE_LABELS,
    MASK_MODE_VALUES,
    load_config,
    save_config,
    wallpaper_output_path,
)
from laniakea.display import wallpaper_pixel_size
from laniakea.wallpaper import apply_with_swaybg, save_png_bytes


def web_root() -> Path:
    env = os.environ.get("LANIAKEA_WEB_ROOT")
    if env:
        return Path(env)
    installed = Path("/usr/share/laniakea/web")
    if (installed / "index.html").is_file():
        return installed
    return Path(__file__).resolve().parents[1] / "share" / "laniakea" / "web"


class LaniakeaWindow(Gtk.ApplicationWindow):
    """Plain Gtk window (SSD) so Swirl's border_radius clips WebKit like other apps.

    Adw CSD + WebKit hardware layers were leaving square corners; disabling
    acceleration fixed corners but hurt drawing quality. SSD keeps both.
    """

    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="Laniakea")
        self.set_default_size(960, 640)
        self.set_size_request(420, 320)
        # No client titlebar — Swirl draws decorations and applies border_radius.
        self.set_decorated(True)
        self._cfg = load_config()
        self._busy = False

        self._install_actions()

        toolbar = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=6,
            margin_start=8,
            margin_end=8,
            margin_top=6,
            margin_bottom=6,
        )
        toolbar.add_css_class("toolbar")

        self._mask = Gtk.DropDown.new_from_strings(MASK_MODE_LABELS)
        self._mask.set_tooltip_text("Shape mask")
        try:
            idx = MASK_MODE_VALUES.index(self._cfg["mask_mode"])
        except ValueError:
            idx = 0
        self._mask.set_selected(idx)
        self._mask.connect("notify::selected", self._on_mask_changed)
        toolbar.append(self._mask)

        self._status = Gtk.Label(
            label="Drawing… click the mask to redraw",
            ellipsize=Pango.EllipsizeMode.END,
            max_width_chars=18,
            hexpand=True,
            xalign=0.0,
        )
        self._status.add_css_class("dim-label")
        toolbar.append(self._status)

        menu = Gio.Menu()
        menu.append("Redraw", "win.redraw")
        menu.append("Save PNG", "win.save")
        menu.append("Apply wallpaper", "win.apply")
        menu_btn = Gtk.MenuButton(
            menu_model=menu,
            icon_name="open-menu-symbolic",
            tooltip_text="Actions",
        )
        toolbar.append(menu_btn)

        apply_btn = Gtk.Button(label="Apply")
        apply_btn.set_tooltip_text("Apply wallpaper")
        apply_btn.add_css_class("suggested-action")
        apply_btn.connect("clicked", lambda *_: self._export(apply=True))
        toolbar.append(apply_btn)

        self._view = WebKit.WebView()
        settings = self._view.get_settings()
        settings.set_enable_write_console_messages_to_stdout(True)
        settings.set_allow_file_access_from_file_urls(True)
        settings.set_allow_universal_access_from_file_urls(True)
        # Restore sharp live drawing (was NEVER in 0.1.4 for corners).
        try:
            settings.set_hardware_acceleration_policy(
                WebKit.HardwareAccelerationPolicy.ALWAYS
            )
        except (AttributeError, TypeError):
            pass

        root = web_root()
        index = root / "index.html"
        if not index.is_file():
            raise SystemExit(f"missing web assets at {root}")
        self._view.connect("load-changed", self._on_load_changed)
        self.connect("notify::scale-factor", self._on_scale_factor)
        self._view.load_uri(index.resolve().as_uri())
        Gtk.Widget.set_vexpand(self._view, True)
        Gtk.Widget.set_hexpand(self._view, True)

        root_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root_box.append(toolbar)
        root_box.append(self._view)
        self.set_child(root_box)

    def _install_actions(self) -> None:
        for name, callback in (
            ("redraw", lambda *_: self._run_js("resetDrawing();")),
            ("save", lambda *_: self._export(apply=False)),
            ("apply", lambda *_: self._export(apply=True)),
        ):
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", callback)
            self.add_action(action)

    def _gtk_scale(self) -> float:
        try:
            return float(self.get_scale_factor())
        except Exception:
            return 1.0

    def _inject_scale_and_mask(self) -> None:
        mode = self._cfg["mask_mode"]
        scale = self._gtk_scale()
        self._run_js(
            f"window.LANIAKEA_GTK_SCALE = {scale};"
            f"if (typeof applyPixelDensity === 'function') applyPixelDensity();"
            f"if (typeof fitCanvasInViewport === 'function') fitCanvasInViewport();"
            f"if (typeof setMaskMode === 'function') setMaskMode({mode!r});"
        )

    def _on_scale_factor(self, *_args) -> None:
        scale = self._gtk_scale()
        self._run_js(
            f"window.LANIAKEA_GTK_SCALE = {scale};"
            f"if (typeof fitCanvasInViewport === 'function') fitCanvasInViewport();"
        )

    def _on_load_changed(self, _view: WebKit.WebView, event: WebKit.LoadEvent) -> None:
        if event != WebKit.LoadEvent.FINISHED:
            return
        self._inject_scale_and_mask()

    def _on_mask_changed(self, dropdown: Gtk.DropDown, *_args) -> None:
        idx = int(dropdown.get_selected())
        if idx < 0 or idx >= len(MASK_MODE_VALUES):
            return
        mode = MASK_MODE_VALUES[idx]
        self._cfg["mask_mode"] = mode
        save_config(self._cfg)
        self._run_js(f"setMaskMode({mode!r});")
        self._status.set_label(f"Mask: {MASK_MODE_LABELS[idx]}")

    def _run_js(self, script: str) -> None:
        self._view.evaluate_javascript(script, -1, None, None, None, None, None)

    def _export(self, *, apply: bool) -> None:
        if self._busy:
            return
        self._busy = True
        width, height = wallpaper_pixel_size(self)
        self._status.set_label(f"Saving what you see → {width}×{height}…")
        self._view.evaluate_javascript(
            f"exportWallpaperPng({width}, {height})",
            -1,
            None,
            None,
            None,
            self._on_export_finished,
            apply,
        )

    def _on_export_finished(self, view: WebKit.WebView, result: Gio.AsyncResult, apply: bool) -> None:
        self._busy = False
        try:
            value = view.evaluate_javascript_finish(result)
        except GLib.Error as exc:
            self._status.set_label(f"Capture failed: {exc.message}")
            return

        data_url = ""
        if value is not None:
            try:
                if hasattr(value, "is_string") and value.is_string():
                    data_url = value.to_string() or ""
                else:
                    data_url = value.to_string() or ""
            except Exception:
                data_url = ""

        if not data_url.startswith("data:image/png;base64,"):
            self._status.set_label("Capture failed: empty canvas")
            return

        raw = base64.b64decode(data_url.split(",", 1)[1])
        dest = wallpaper_output_path()
        try:
            save_png_bytes(raw, dest)
        except OSError as exc:
            self._status.set_label(f"Save failed: {exc}")
            return

        if not apply:
            self._status.set_label(f"Saved {dest}")
            return

        try:
            apply_with_swaybg(dest)
        except RuntimeError as exc:
            self._status.set_label(str(exc))
            return
        self._status.set_label(f"Wallpaper applied → {dest}")


class LaniakeaApp(Gtk.Application):
    # Gtk.Application (not Adw) so the window can use Swirl server-side
    # decorations and pick up border_radius like foot/other SSD apps.
    def __init__(self) -> None:
        super().__init__(
            application_id="io.github.visnudeva.Laniakea",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )

    def do_activate(self) -> None:
        win = self.props.active_window
        if not win:
            win = LaniakeaWindow(self)
        win.present()


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv if argv is None else argv)
    Adw.init()
    app = LaniakeaApp()
    return app.run(argv)
