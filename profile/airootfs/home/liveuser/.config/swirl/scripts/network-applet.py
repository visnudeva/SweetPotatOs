#!/usr/bin/env python3
"""SweetPotato network tray — click opens networkmanager-dmenu (quick Wi‑Fi).

Exports a StatusNotifierItem for swaybar. Left-click launches
networkmanager_dmenu (same as Mod+n). Retries watcher registration so the
icon appears even if swaybar's tray starts after this process.
"""
from __future__ import annotations

import os
import subprocess
import sys

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

ID = "sweetpotato-network"
# Papirus panel icon (network-wireless often missing → red face fallback)
ICON = "nm-device-wireless"
BUS_NAME = f"org.kde.StatusNotifierItem-{os.getpid()}-1"
OBJECT_PATH = "/StatusNotifierItem"
WATCHER_NAME = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
WATCHER_IFACE = "org.kde.StatusNotifierWatcher"
ITEM_IFACE = "org.kde.StatusNotifierItem"
LAUNCH = "networkmanager_dmenu"

INTROSPECTION_XML = f"""
<node>
  <interface name="{ITEM_IFACE}">
    <property name="Category" type="s" access="read"/>
    <property name="Id" type="s" access="read"/>
    <property name="Title" type="s" access="read"/>
    <property name="Status" type="s" access="read"/>
    <property name="WindowId" type="i" access="read"/>
    <property name="IconName" type="s" access="read"/>
    <property name="IconThemePath" type="s" access="read"/>
    <property name="ItemIsMenu" type="b" access="read"/>
    <property name="Menu" type="o" access="read"/>
    <property name="ToolTip" type="(sa(iiay)ss)" access="read"/>
    <method name="Activate">
      <arg type="i" name="x" direction="in"/>
      <arg type="i" name="y" direction="in"/>
    </method>
    <method name="SecondaryActivate">
      <arg type="i" name="x" direction="in"/>
      <arg type="i" name="y" direction="in"/>
    </method>
    <method name="ContextMenu">
      <arg type="i" name="x" direction="in"/>
      <arg type="i" name="y" direction="in"/>
    </method>
    <method name="Scroll">
      <arg type="i" name="delta" direction="in"/>
      <arg type="s" name="orientation" direction="in"/>
    </method>
  </interface>
</node>
"""

_connection: Gio.DBusConnection | None = None
_registered = False


def open_wifi_menu(*_args) -> None:
    subprocess.Popen([LAUNCH], start_new_session=True)


def on_method_call(
    _connection, _sender, _path, _interface, method, _params, invocation
):
    if method in ("Activate", "SecondaryActivate", "ContextMenu"):
        open_wifi_menu()
        invocation.return_value(None)
        return
    if method == "Scroll":
        invocation.return_value(None)
        return
    invocation.return_error_literal(
        Gio.dbus_error_quark(),
        Gio.DBusError.UNKNOWN_METHOD,
        f"Unknown method {method}",
    )


def on_get_property(_connection, _sender, _path, _interface, prop):
    props = {
        "Category": GLib.Variant("s", "Hardware"),
        "Id": GLib.Variant("s", ID),
        "Title": GLib.Variant("s", "Network"),
        "Status": GLib.Variant("s", "Active"),
        "WindowId": GLib.Variant("i", 0),
        "IconName": GLib.Variant("s", ICON),
        "IconThemePath": GLib.Variant("s", ""),
        "ItemIsMenu": GLib.Variant("b", False),
        # Some hosts require Menu even when ItemIsMenu is false.
        "Menu": GLib.Variant("o", "/StatusNotifierItem/menu"),
        "ToolTip": GLib.Variant(
            "(sa(iiay)ss)",
            ("", [], "Network", "Wi‑Fi (networkmanager-dmenu)"),
        ),
    }
    return props.get(prop)


def try_register() -> bool:
    global _registered
    if _registered or _connection is None:
        return _registered

    unique = _connection.get_unique_name() or ""
    # Sway/wlroots prefer ":1.N/StatusNotifierItem"; also try well-known name.
    candidates = []
    if unique:
        candidates.append(f"{unique}{OBJECT_PATH}")
    candidates.append(BUS_NAME)
    candidates.append(OBJECT_PATH)

    for service in candidates:
        try:
            _connection.call_sync(
                WATCHER_NAME,
                WATCHER_PATH,
                WATCHER_IFACE,
                "RegisterStatusNotifierItem",
                GLib.Variant("(s)", (service,)),
                None,
                Gio.DBusCallFlags.NONE,
                2500,
                None,
            )
            _registered = True
            print(f"[network-applet] registered with watcher as {service}", flush=True)
            return True
        except GLib.Error:
            continue

    return False


def on_name_appeared(_conn, _name, _owner) -> None:
    try_register()


def schedule_register_retries() -> None:
    attempts = {"n": 0}

    def tick() -> bool:
        if try_register():
            return False
        attempts["n"] += 1
        if attempts["n"] >= 30:
            print(
                "[network-applet] tray watcher never appeared; no Wi‑Fi icon",
                file=sys.stderr,
                flush=True,
            )
            return False
        return True

    GLib.timeout_add_seconds(1, tick)


def on_bus_acquired(connection: Gio.DBusConnection, _name: str) -> None:
    global _connection
    _connection = connection
    node = Gio.DBusNodeInfo.new_for_xml(INTROSPECTION_XML)
    connection.register_object(
        OBJECT_PATH,
        node.interfaces[0],
        on_method_call,
        on_get_property,
        None,
    )
    Gio.bus_watch_name_on_connection(
        connection,
        WATCHER_NAME,
        Gio.BusNameWatcherFlags.NONE,
        on_name_appeared,
        None,
    )
    try_register()
    schedule_register_retries()


def main() -> int:
    if not GLib.find_program_in_path(LAUNCH):
        print(f"[network-applet] {LAUNCH} not found", file=sys.stderr)
        return 1

    owner_id = Gio.bus_own_name(
        Gio.BusType.SESSION,
        BUS_NAME,
        Gio.BusNameOwnerFlags.NONE,
        on_bus_acquired,
        None,
        None,
    )
    if owner_id == 0:
        print("[network-applet] failed to own bus name", file=sys.stderr)
        return 1

    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
