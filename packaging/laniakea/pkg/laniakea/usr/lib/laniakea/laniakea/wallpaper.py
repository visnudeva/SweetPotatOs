# SPDX-License-Identifier: GPL-3.0-or-later
from __future__ import annotations

import configparser
import os
import shutil
import subprocess
from pathlib import Path


def _expand(path: str) -> str:
    return os.path.expanduser(path)


def update_waypaper_config(image: Path) -> None:
    """Point waypaper at the new image so the next login restore keeps it."""
    conf = Path.home() / ".config" / "waypaper" / "config.ini"
    if not conf.is_file():
        return
    parser = configparser.ConfigParser()
    parser.read(conf)
    if "Settings" not in parser:
        parser["Settings"] = {}
    parser["Settings"]["wallpaper"] = str(image)
    parser["Settings"]["backend"] = "swaybg"
    parser["Settings"]["fill"] = "fill"
    conf.parent.mkdir(parents=True, exist_ok=True)
    with conf.open("w", encoding="utf-8") as fh:
        parser.write(fh)


def apply_with_swaybg(image: Path) -> None:
    """Replace the current swaybg instance with this image (fill)."""
    image = image.resolve()
    if shutil.which("waypaper"):
        # Prefer waypaper so restore + GUI stay in sync.
        subprocess.Popen(
            ["waypaper", "--wallpaper", str(image)],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        update_waypaper_config(image)
        return

    # Fallback: kill previous swaybg and start a new one.
    subprocess.run(["pkill", "-x", "swaybg"], check=False)
    if not shutil.which("swaybg"):
        raise RuntimeError("neither waypaper nor swaybg is available")
    subprocess.Popen(
        ["swaybg", "-i", str(image), "-m", "fill"],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    update_waypaper_config(image)


def save_png_bytes(data: bytes, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    return dest
