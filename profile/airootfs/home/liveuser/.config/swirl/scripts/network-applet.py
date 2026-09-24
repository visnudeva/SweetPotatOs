#!/usr/bin/env python3
"""SweetPotato network tray — click opens networkmanager-dmenu (quick Wi‑Fi).

Uses Ayatana AppIndicator (same tray stack as Blueman / LocalSend on Swirl),
not a hand-rolled StatusNotifierItem — those showed a red face and ate clicks
under swaybar.
"""
from __future__ import annotations

import os
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import AyatanaAppIndicator3 as AppIndicator3  # noqa: E402
from gi.repository import GLib, Gtk  # noqa: E402

ID = "sweetpotato-network"
LAUNCH = "networkmanager_dmenu"

# Prefer a concrete Papirus *panel* icon file (theme name lookup is flaky in trays).
ICON_CANDIDATES = (
    "/usr/share/icons/Papirus/24x24/panel/nm-device-wireless.svg",
    "/usr/share/icons/Papirus-Dark/24x24/panel/nm-device-wireless.svg",
    "/usr/share/icons/Papirus/24x24/panel/network-wireless-signal-excellent.svg",
    "/usr/share/icons/Papirus/24x24/panel/network-wireless-connected-symbolic.svg",
    "nm-device-wireless",
    "network-wireless",
)


def resolve_icon() -> str:
    for cand in ICON_CANDIDATES:
        if cand.startswith("/") and os.path.isfile(cand):
            return cand
        if not cand.startswith("/"):
            theme = Gtk.IconTheme.get_default()
            if theme.has_icon(cand):
                return cand
    return "network-wired"


def open_wifi_menu(*_args) -> None:
    subprocess.Popen([LAUNCH], start_new_session=True)


def main() -> int:
    if not GLib.find_program_in_path(LAUNCH):
        print(f"[network-applet] {LAUNCH} not found", file=sys.stderr)
        return 1

    Gtk.init_check(sys.argv)
    icon = resolve_icon()

    indicator = AppIndicator3.Indicator.new(
        ID,
        icon if not icon.startswith("/") else "nm-device-wireless",
        AppIndicator3.IndicatorCategory.SYSTEM_SERVICES,
    )
    indicator.set_status(AppIndicator3.IndicatorStatus.ACTIVE)
    indicator.set_title("Network")
    indicator.set_icon_full(icon, "Wi‑Fi")

    menu = Gtk.Menu()
    item = Gtk.MenuItem(label="Wi‑Fi networks…")
    item.connect("activate", open_wifi_menu)
    menu.append(item)
    menu.show_all()
    indicator.set_menu(menu)
    indicator.set_secondary_activate_target(item)

    # Left-click opens the AppIndicator menu; treat that as "open Wi‑Fi".
    # (Blueman can hijack Activate; AppIndicator always shows a menu first.)
    opening = {"yes": False}

    def on_menu_show(_menu: Gtk.Menu) -> None:
        if opening["yes"]:
            return
        opening["yes"] = True
        open_wifi_menu()

        def reset_and_hide() -> bool:
            try:
                menu.popdown()
            except Exception:
                pass
            opening["yes"] = False
            return False

        GLib.timeout_add(50, reset_and_hide)

    menu.connect("show", on_menu_show)

    print(f"[network-applet] tray ready icon={icon}", flush=True)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
