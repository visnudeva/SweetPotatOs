# SPDX-License-Identifier: GPL-3.0-or-later
from __future__ import annotations

import json
import shutil
import subprocess
from typing import Any


def _from_sway() -> tuple[int, int] | None:
    """Largest active output mode from swirlmsg/swaymsg (logical × scale)."""
    binary = None
    for name in ("swirlmsg", "swaymsg"):
        if shutil.which(name):
            binary = name
            break
    if not binary:
        return None
    try:
        raw = subprocess.check_output(
            [binary, "-t", "get_outputs"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
        outputs = json.loads(raw)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return None

    best = (0, 0)
    for out in outputs:
        if not out.get("active", True):
            continue
        mode = out.get("current_mode") or {}
        width = int(mode.get("width") or 0)
        height = int(mode.get("height") or 0)
        # Prefer the mode's native pixels when present; else logical × scale.
        if width <= 0 or height <= 0:
            rect = out.get("rect") or {}
            scale = float(out.get("scale") or 1.0)
            width = int(rect.get("width") or 0) * scale
            height = int(rect.get("height") or 0) * scale
            width, height = int(width), int(height)
        if width * height > best[0] * best[1]:
            best = (width, height)
    return best if best[0] > 0 and best[1] > 0 else None


def _from_gdk(window: Any | None = None) -> tuple[int, int] | None:
    try:
        import gi

        gi.require_version("Gdk", "4.0")
        from gi.repository import Gdk
    except (ImportError, ValueError):
        return None

    display = Gdk.Display.get_default()
    if display is None:
        return None

    monitor = None
    if window is not None:
        surface = window.get_surface()
        if surface is not None:
            monitor = display.get_monitor_at_surface(surface)
    if monitor is None:
        monitor = display.get_monitors().get_item(0)
    if monitor is None:
        return None

    geo = monitor.get_geometry()
    scale = float(monitor.get_scale_factor())
    return (max(1, int(geo.width * scale)), max(1, int(geo.height * scale)))


def wallpaper_pixel_size(window: Any | None = None) -> tuple[int, int]:
    """Native-ish pixel size for a sharp wallpaper PNG."""
    for getter in (_from_sway, lambda: _from_gdk(window)):
        size = getter()
        if size:
            # Cap absurd multi-monitor spans if someone reports a huge virtual size.
            w, h = size
            w = min(w, 7680)
            h = min(h, 4320)
            return (max(w, 1280), max(h, 720))
    return (1920, 1080)
