"""Shared SweetPotatOs panel look — Settings, themer, keybinds.

Matches frame.sh chrome: 8px radius, 2px-feel borders, accent switch.
"""
from __future__ import annotations

from pathlib import Path

RADIUS = 8
ACCENT_DEFAULT = "a73b50"
HIGHLIGHT_DEFAULT = "f79b29"
ON_HIGHLIGHT_DEFAULT = "1d1f21"


def theme_mode(root: Path) -> str:
    theme = root / "sweetpotatos" / "theme"
    if theme.is_file():
        for line in theme.read_text().splitlines():
            if line.startswith("mode="):
                return line.split("=", 1)[1].strip() or "dark"
            if line.startswith("id=") and "light" in line.split("=", 1)[1]:
                return "light"
    return "dark"


def _active_hex(root: Path, key: str, default: str) -> str:
    active = root / "sweetpotatos" / "active.sh"
    if active.is_file():
        for line in active.read_text().splitlines():
            if line.startswith(f"{key}="):
                val = line.split("=", 1)[1].strip().strip("'\"")
                if len(val) == 6:
                    return val
    return default


def accent_hex(root: Path) -> str:
    return _active_hex(root, "SPO_ACCENT", ACCENT_DEFAULT)


def highlight_hex(root: Path) -> str:
    mode = theme_mode(root)
    default = "c45a1a" if mode == "light" else HIGHLIGHT_DEFAULT
    return _active_hex(root, "SPO_HIGHLIGHT", default)


def on_highlight_hex(root: Path) -> str:
    mode = theme_mode(root)
    default = "f4f1ec" if mode == "light" else ON_HIGHLIGHT_DEFAULT
    return _active_hex(root, "SPO_ON_HIGHLIGHT", default)


def darken_hex(hex_color: str, factor: float = 0.88) -> str:
    """Slightly deepen a fill so a solid button matches orange text weight."""
    hex_color = hex_color.lstrip("#")
    parts = []
    for i in (0, 2, 4):
        channel = int(hex_color[i : i + 2], 16)
        parts.append(f"{max(0, min(255, round(channel * factor))):02x}")
    return "".join(parts)


def palette(
    mode: str,
    accent: str | None = None,
    highlight: str | None = None,
    on_highlight: str | None = None,
) -> dict[str, str]:
    accent = (accent or ACCENT_DEFAULT).lstrip("#")
    if mode == "light":
        highlight = (highlight or "c45a1a").lstrip("#")
        on_highlight = (on_highlight or "f4f1ec").lstrip("#")
        return {
            "bg": "f4f1ec",
            "fg": "241e20",
            "raised": "e8e2d8",
            "hover": "e0d9cf",
            "border": "d4cdc2",
            "muted": "6e6760",
            "accent": accent,
            "highlight": highlight,
            "on_highlight": on_highlight,
            "highlight_fill": darken_hex(highlight, 0.9),
        }
    highlight = (highlight or HIGHLIGHT_DEFAULT).lstrip("#")
    on_highlight = (on_highlight or ON_HIGHLIGHT_DEFAULT).lstrip("#")
    return {
        "bg": "1d1f21",
        "fg": "f5e6e8",
        "raised": "222426",
        "hover": "2c3032",
        "border": "2e3234",
        "muted": "aaaaaa",
        "accent": accent,
        "highlight": highlight,
        "on_highlight": on_highlight,
        # Solid fills read lighter than the same hex as text — deepen a touch.
        "highlight_fill": darken_hex(highlight, 0.88),
    }


def panel_css(
    mode: str,
    accent: str | None = None,
    highlight: str | None = None,
    on_highlight: str | None = None,
) -> bytes:
    """GTK CSS for floating SPO panels (Settings / themer / keybinds)."""
    p = palette(mode, accent, highlight, on_highlight)
    r = RADIUS
    return f"""
            window, decoration.background, .background {{
              background-color: #{p['bg']};
              color: #{p['fg']};
              border-radius: {r}px;
            }}
            label {{ color: #{p['fg']}; }}
            #title {{
              color: #{p['fg']};
              font-weight: bold;
              font-size: 14pt;
            }}
            #section {{
              color: #{p['highlight']};
              font-weight: bold;
              margin-top: 4px;
            }}
            #muted {{ color: #{p['muted']}; }}
            #bind-key {{
              color: #{p['accent']};
              font-family: monospace;
              font-weight: bold;
            }}
            #bind-desc {{ color: #{p['fg']}; }}
            button {{
              background-image: none;
              background-color: #{p['raised']};
              color: #{p['fg']};
              border: 1px solid #{p['border']};
              border-radius: {r}px;
              padding: 4px 10px;
              min-height: 28px;
            }}
            button:hover {{
              background-image: none;
              background-color: #{p['hover']};
              color: #{p['fg']};
              border-color: #{p['accent']};
            }}
            button.suggested-action {{
              background-image: none;
              background-color: #{p['accent']};
              color: #ffffff;
              border-color: #{p['accent']};
            }}
            button.suggested-action:hover {{
              background-image: none;
              background-color: #{p['hover']};
              color: #{p['fg']};
            }}
            button.spo-update {{
              background-image: none;
              background-color: #{p['highlight_fill']};
              color: #{p['on_highlight']};
              border-color: #{p['highlight']};
              font-weight: bold;
            }}
            button.spo-update:hover {{
              background-image: none;
              background-color: #{p['highlight']};
              color: #{p['on_highlight']};
              border-color: #{p['highlight']};
            }}
            switch {{
              background-color: #{p['raised']};
              border-color: #{p['border']};
              border-radius: {r}px;
            }}
            switch:checked {{
              background-color: #{p['accent']};
              border-color: #{p['accent']};
            }}
            switch slider {{
              border-radius: {max(2, r - 2)}px;
            }}
            scrolledwindow {{
              border: none;
              background-color: #{p['bg']};
            }}
            scrollbar slider {{
              background-color: #{p['border']};
              border-radius: {r}px;
              min-width: 8px;
            }}
            scale trough {{
              background-color: #{p['raised']};
              border-radius: {r}px;
            }}
            scale highlight {{
              background-color: #{p['accent']};
              border-radius: {r}px;
            }}
            radiobutton {{ color: #{p['fg']}; }}
            """.encode()


def paint_window_bg(cr, bg_rgb, width: int, height: int) -> None:
    """Rounded fill for set_app_paintable windows (matches RADIUS)."""
    import math

    r, g, b = bg_rgb
    rad = float(RADIUS)
    cr.set_source_rgb(r, g, b)
    w, h = float(width), float(height)
    if w <= 0 or h <= 0:
        return
    rad = min(rad, w / 2, h / 2)
    cr.new_sub_path()
    cr.arc(w - rad, rad, rad, -math.pi / 2, 0)
    cr.arc(w - rad, h - rad, rad, 0, math.pi / 2)
    cr.arc(rad, h - rad, rad, math.pi / 2, math.pi)
    cr.arc(rad, rad, rad, math.pi, 3 * math.pi / 2)
    cr.close_path()
    cr.fill()
