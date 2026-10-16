#!/usr/bin/env python3
"""Smart Brightness helpers for Swirl (ported from fullscreen-maxbright)."""

from __future__ import annotations

import json
import sys
from typing import Any

# Keep in sync with visnudeva/fullscreen-maxbright lib/video-detection.js
MEDIA_WINDOW_CLASSES = (
    "vlc",
    "mpv",
    "celluloid",
    "totem",
    "smplayer",
    "gnome-mpv",
    "parole",
    "dragon",
    "kaffeine",
    "xine",
    "mplayer",
    "audacious",
    "clementine",
    "rhythmbox",
    "stremio",
    "jellyfin",
    "jellyfin-media-player",
    "fladder",
    "plex",
    "plexhometheater",
    "kodi",
    "osmc",
    "libreelec",
    "firefox",
    "chrome",
    "chromium",
    "brave",
    "zen",
    "waterfox",
    "librewolf",
    "floorp",
)

VIDEO_TITLE_KEYWORDS = (
    "youtube",
    "vimeo",
    "netflix",
    "prime video",
    "disney",
    "hulu",
    "twitch",
    "video",
    "media",
    "vlc",
    "mpv",
    "watch",
    "play",
    "movie",
    "film",
    "stremio",
    "jellyfin",
    "plex",
    "kodi",
    "emby",
    "plexamp",
    "spotify",
    "tidal",
    "soundcloud",
    "bandcamp",
)


def should_activate_video_mode(
    *,
    is_fullscreen: bool,
    window_class: str = "",
    window_title: str = "",
) -> bool:
    """True only for compositor fullscreen plus a media app or media title."""
    if not is_fullscreen:
        return False
    cls = (window_class or "").lower()
    title = (window_title or "").lower()
    is_video_player = any(c in cls for c in MEDIA_WINDOW_CLASSES)
    is_media_title = any(keyword in title for keyword in VIDEO_TITLE_KEYWORDS)
    return is_video_player or is_media_title


def _walk(node: dict[str, Any]):
    yield node
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key) or []:
            yield from _walk(child)


def focused_window(tree: dict[str, Any]) -> dict[str, Any] | None:
    for node in _walk(tree):
        if not node.get("focused"):
            continue
        # Outputs / workspaces can be focused; only containers are windows.
        if node.get("type") in ("con", "floating_con"):
            return node
    return None


def window_identity(node: dict[str, Any]) -> tuple[bool, str, str]:
    """Return (is_fullscreen, class_or_app_id, title)."""
    fullscreen = int(node.get("fullscreen_mode") or 0) != 0
    app_id = node.get("app_id") or ""
    props = node.get("window_properties") or {}
    xclass = props.get("class") or props.get("instance") or ""
    window_class = app_id or xclass
    title = node.get("name") or props.get("title") or ""
    return fullscreen, window_class, title


def should_activate_from_tree(tree: dict[str, Any]) -> bool:
    node = focused_window(tree)
    if node is None:
        return False
    is_fs, cls, title = window_identity(node)
    return should_activate_video_mode(
        is_fullscreen=is_fs,
        window_class=cls,
        window_title=title,
    )


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[1] == "check-tree":
        tree = json.load(sys.stdin)
        print("1" if should_activate_from_tree(tree) else "0")
        return 0
    if len(argv) >= 5 and argv[1] == "check":
        # check <fullscreen 0|1> <class> <title...>
        is_fs = argv[2] in ("1", "true", "True", "yes")
        cls = argv[3]
        title = " ".join(argv[4:])
        print(
            "1"
            if should_activate_video_mode(
                is_fullscreen=is_fs, window_class=cls, window_title=title
            )
            else "0"
        )
        return 0
    print(
        "Usage: smart-brightness-lib.py check-tree < tree.json\n"
        "       smart-brightness-lib.py check <0|1> <class> <title>",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
