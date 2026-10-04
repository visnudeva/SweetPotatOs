#!/usr/bin/env python3
"""Theme presets, plus accent and highlight sliders. Apply commits."""
import math
import os
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import GLib

GLib.set_prgname("sweetpotato-themes")
from gi.repository import Gdk, Gtk  # noqa: E402

ROOT = Path(os.environ.get("SPO_CONFIG_ROOT", Path.home() / ".config"))
HUES = ROOT / "sweetpotatos" / "hues"
THEME = ROOT / "sweetpotatos" / "theme"
SCRIPT = Path(__file__).resolve().parent / "theme.sh"
DEFAULT_ACCENT = 348.33
DEFAULT_HIGHLIGHT = 33.20


def shift(hex_color, hue):
    import colorsys

    r, g, b = [int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    _h, light, sat = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb((hue % 360) / 360.0, light, sat)
    return "".join(f"{max(0, min(255, round(c * 255))):02x}" for c in (r, g, b))


def hue_of(hex_color):
    import colorsys

    r, g, b = [int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    hue, _light, _sat = colorsys.rgb_to_hls(r, g, b)
    return (hue * 360) % 360


def read_hues():
    """Saved slider for one preset. Older files without an id belong to sweet potato."""
    accent, highlight, ident = DEFAULT_ACCENT, DEFAULT_HIGHLIGHT, "sweet-potato"
    seen_id = False
    if HUES.is_file():
        for line in HUES.read_text().splitlines():
            if "=" not in line:
                continue
            key, val = line.split("=", 1)
            if key == "id":
                ident = val.strip() or ident
                seen_id = True
                continue
            try:
                number = float(val)
            except ValueError:
                continue
            if key == "accent_hue":
                accent = number % 360
            elif key == "highlight_hue":
                highlight = number % 360
    if not seen_id:
        ident = "sweet-potato"
    return ident, accent, highlight


def current_id():
    if THEME.is_file():
        for line in THEME.read_text().splitlines():
            if line.startswith("id="):
                return line.split("=", 1)[1].strip() or "sweet-potato"
    return "sweet-potato"


def load_presets():
    out = subprocess.check_output([str(SCRIPT), "presets"], text=True)
    rows = []
    for line in out.splitlines():
        if not line.strip():
            continue
        ident, name, mode, surface, accent, highlight = line.split("\t")
        rows.append(
            {
                "id": ident,
                "name": name,
                "mode": mode,
                "surface": surface,
                "accent": accent,
                "highlight": highlight,
            }
        )
    return rows


class Picker(Gtk.Window):
    def __init__(self):
        super().__init__(title="SweetPotato themer")
        self.set_default_size(380, -1)
        self.set_resizable(False)
        self.set_app_paintable(True)
        self._bg = (0x1D / 255, 0x1F / 255, 0x21 / 255)
        self.presets = load_presets()
        self._preset_id = current_id()
        self._chips = {}
        self._building = False
        self._setting = False
        self._css = Gtk.CssProvider()
        # User gtk.css is loaded at the same priority and keeps the old
        # window fill after a theme switch. This provider is more specific,
        # and do_draw paints the fill so a stale cache cannot leave it behind.
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            self._css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )
        start = next(
            (row["mode"] for row in self.presets if row["id"] == self._preset_id),
            "dark",
        )
        self._apply_css(start)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(16)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)
        self.add(box)

        title = Gtk.Label(label="SweetPotato themer")
        title.set_name("title")
        title.set_xalign(0)
        box.pack_start(title, False, False, 0)

        modes = Gtk.Box(spacing=8)
        self.dark = Gtk.RadioButton.new_with_label_from_widget(None, "Dark")
        self.light = Gtk.RadioButton.new_with_label_from_widget(self.dark, "Light")
        if start == "light":
            self.light.set_active(True)
        modes.pack_start(self.dark, False, False, 0)
        modes.pack_start(self.light, False, False, 0)
        box.pack_start(modes, False, False, 0)

        self.preset_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.pack_start(self.preset_box, False, False, 0)

        self.slider_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.accent_scale, self.accent_swatch = self._slider(self.slider_box, "Accent", 0)
        self.highlight_scale, self.highlight_swatch = self._slider(
            self.slider_box, "Highlight", 0
        )
        box.pack_start(self.slider_box, False, False, 0)

        buttons = Gtk.Box(spacing=8)
        apply = Gtk.Button.new_with_label("Apply")
        apply.connect("clicked", lambda *_args: self.apply())
        reset = Gtk.Button.new_with_label("Reset")
        reset.connect("clicked", self._on_reset)
        buttons.pack_start(apply, False, False, 0)
        buttons.pack_start(reset, False, False, 0)
        box.pack_start(buttons, False, False, 0)

        self.dark.connect("toggled", self._on_mode)
        self.light.connect("toggled", self._on_mode)
        self._rebuild_presets(self._preset_id)
        self.refresh_swatches()

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
        self._ring = fg
        self._css.load_from_data(
            f"""
            window, window.background, .background {{
              background-color: #{bg};
              color: #{fg};
            }}
            label {{ color: #{fg}; }}
            #title {{ color: #{fg}; font-weight: bold; }}
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
            """.encode()
        )
        self.queue_draw()
        self._redraw_dots()

    def _slider(self, box, title, value):
        label = Gtk.Label(label=title)
        label.set_xalign(0)
        box.pack_start(label, False, False, 0)
        row = Gtk.Box(spacing=8)
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 360, 1)
        scale.set_value(value)
        scale.set_draw_value(False)
        scale.set_hexpand(True)
        scale.connect("value-changed", self._on_value)
        swatch = self._dot(22)
        row.pack_start(scale, True, True, 0)
        row.pack_start(swatch, False, False, 0)
        box.pack_start(row, False, False, 0)
        return scale, swatch

    def mode(self):
        return "light" if self.light.get_active() else "dark"

    def _rebuild_presets(self, selected):
        self._building = True
        self._chips = {}
        for child in self.preset_box.get_children():
            self.preset_box.remove(child)
        group = None
        chosen = None
        chosen_id = None
        first = None
        first_id = None
        for row in self.presets:
            if row["mode"] != self.mode():
                continue
            radio = Gtk.RadioButton.new_with_label_from_widget(group, row["name"])
            group = radio
            radio.connect("toggled", self._on_preset, row["id"])
            line = Gtk.Box(spacing=8)
            accent = self._dot(16)
            highlight = self._dot(16)
            self._paint(accent, row["accent"])
            self._paint(highlight, row["highlight"])
            self._chips[row["id"]] = (accent, highlight)
            line.pack_start(radio, True, True, 0)
            line.pack_start(accent, False, False, 0)
            line.pack_start(highlight, False, False, 0)
            self.preset_box.pack_start(line, False, False, 0)
            if first is None:
                first = radio
                first_id = row["id"]
            if row["id"] == selected:
                chosen = radio
                chosen_id = row["id"]
        if chosen is None:
            chosen = first
            chosen_id = first_id
        if chosen is not None:
            chosen.set_active(True)
            self._preset_id = chosen_id
        self._building = False
        self._show_preset_hues()
        self.preset_box.show_all()

    def _on_mode(self, button):
        if not button.get_active():
            return
        fallback = "sweet-potato-light" if self.mode() == "light" else "sweet-potato"
        self._rebuild_presets(fallback)

    def _on_preset(self, button, ident):
        if self._building or not button.get_active():
            return
        self._preset_id = ident
        self._show_preset_hues()

    def _preset(self):
        for row in self.presets:
            if row["id"] == self._preset_id:
                return row
        return self.presets[0]

    def _show_preset_hues(self):
        row = self._preset()
        accent, highlight = hue_of(row["accent"]), hue_of(row["highlight"])
        saved_id, saved_accent, saved_highlight = read_hues()
        if saved_id == row["id"]:
            accent, highlight = saved_accent, saved_highlight
        self._setting = True
        self.accent_scale.set_value(accent)
        self.highlight_scale.set_value(highlight)
        self._setting = False
        self.refresh_swatches()

    def refresh_swatches(self):
        if self._setting:
            return
        row = self._preset()
        accent = shift(row["accent"], self.accent_scale.get_value())
        highlight = shift(row["highlight"], self.highlight_scale.get_value())
        self._paint(self.accent_swatch, accent)
        self._paint(self.highlight_swatch, highlight)
        chips = self._chips.get(self._preset_id)
        if chips is not None:
            self._paint(chips[0], accent)
            self._paint(chips[1], highlight)

    def _dot(self, size):
        area = Gtk.DrawingArea()
        area.set_size_request(size, size)
        area._spo_hex = "000000"
        area.connect("draw", self._draw_dot)
        return area

    def _redraw_dots(self):
        for widget in (
            getattr(self, "accent_swatch", None),
            getattr(self, "highlight_swatch", None),
        ):
            if widget is not None:
                widget.queue_draw()
        for pair in self._chips.values():
            for widget in pair:
                widget.queue_draw()

    def _draw_dot(self, widget, cr):
        hex_color = widget._spo_hex
        red = int(hex_color[0:2], 16) / 255
        green = int(hex_color[2:4], 16) / 255
        blue = int(hex_color[4:6], 16) / 255
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        cx, cy = width / 2, height / 2
        line = 1.25
        radius = min(width, height) / 2 - line / 2 - 0.5
        cr.set_source_rgb(red, green, blue)
        cr.arc(cx, cy, radius, 0, 2 * math.pi)
        cr.fill()
        ring = getattr(self, "_ring", "f5e6e8")
        cr.set_source_rgb(
            int(ring[0:2], 16) / 255,
            int(ring[2:4], 16) / 255,
            int(ring[4:6], 16) / 255,
        )
        cr.set_line_width(line)
        cr.arc(cx, cy, radius, 0, 2 * math.pi)
        cr.stroke()
        return False

    def _paint(self, widget, hex_color):
        widget._spo_hex = hex_color
        widget.queue_draw()

    def _on_value(self, *_args):
        if self._setting:
            return
        self.refresh_swatches()

    def _on_reset(self, *_args):
        row = self._preset()
        self._setting = True
        self.accent_scale.set_value(hue_of(row["accent"]))
        self.highlight_scale.set_value(hue_of(row["highlight"]))
        self._setting = False
        self.refresh_swatches()

    def apply(self):
        row = self._preset()
        subprocess.run(
            [
                str(SCRIPT),
                "--quiet",
                "hue-apply",
                row["id"],
                f"{self.accent_scale.get_value():.2f}",
                f"{self.highlight_scale.get_value():.2f}",
            ],
            check=False,
        )
        self._apply_css(row["mode"])


def float_window():
    subprocess.run(
        ["swaymsg", '[app_id="sweetpotato-themes"] floating enable'],
        check=False,
    )
    return False


def main():
    win = Picker()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    GLib.timeout_add(150, float_window)
    Gtk.main()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"themes: {exc}", file=sys.stderr)
        subprocess.run(
            [
                "notify-send",
                "-a",
                "SweetPotato",
                "Themes",
                "The theme window could not open.",
            ],
            check=False,
        )
        sys.exit(1)
