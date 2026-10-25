# SPDX-License-Identifier: GPL-3.0-or-later
from __future__ import annotations

import json
from pathlib import Path

MASK_MODE_VALUES = [
    "circle",
    "triangle-up",
    "triangle-down",
    "diamond",
    "hexagon",
    "rectangle-vertical",
    "rectangle-horizontal",
    "wide",
]

MASK_MODE_LABELS = [
    "Circle",
    "Triangle up",
    "Triangle down",
    "Diamond",
    "Hexagon",
    "Vertical rectangle",
    "Horizontal rectangle",
    "Wide",
]

DEFAULT_MASK = "circle"


def config_dir() -> Path:
    xdg = Path.home() / ".config" / "laniakea"
    xdg.mkdir(parents=True, exist_ok=True)
    return xdg


def config_path() -> Path:
    return config_dir() / "config.json"


def load_config() -> dict:
    path = config_path()
    if not path.is_file():
        return {"mask_mode": DEFAULT_MASK}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"mask_mode": DEFAULT_MASK}
    mode = data.get("mask_mode", DEFAULT_MASK)
    if mode not in MASK_MODE_VALUES:
        mode = DEFAULT_MASK
    return {"mask_mode": mode}


def save_config(data: dict) -> None:
    path = config_path()
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def wallpaper_output_path() -> Path:
    pictures = Path.home() / "Pictures" / "Wallpapers"
    pictures.mkdir(parents=True, exist_ok=True)
    return pictures / "laniakea.png"
