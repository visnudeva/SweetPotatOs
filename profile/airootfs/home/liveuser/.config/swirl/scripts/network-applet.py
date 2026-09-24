#!/usr/bin/env python3
"""SweetPotato network tray — click opens networkmanager-dmenu (quick Wi‑Fi).

nm-applet's dbusmenu often does nothing under swaybar; blueman works because
left-click activates a window. Mirror that for NetworkManager by exporting a
StatusNotifierItem whose Activate launches networkmanager_dmenu.
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
ICON = "network-wireless"
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
        "Category": GLib.Variant("s", "SystemServices"),
        "Id": GLib.Variant("s", ID),
        "Title": GLib.Variant("s", "Network"),
        "Status": GLib.Variant("s", "Active"),
        "WindowId": GLib.Variant("i", 0),
        "IconName": GLib.Variant("s", ICON),
        "IconThemePath": GLib.Variant("s", ""),
        "ItemIsMenu": GLib.Variant("b", False),
        "ToolTip": GLib.Variant(
            "(sa(iiay)ss)",
            ("", [], "Network", "Wi‑Fi (networkmanager-dmenu)"),
        ),
    }
    return props.get(prop)


def register_with_watcher(connection: Gio.DBusConnection) -> None:
    try:
        connection.call_sync(
            WATCHER_NAME,
            WATCHER_PATH,
            WATCHER_IFACE,
            "RegisterStatusNotifierItem",
            GLib.Variant("(s)", (BUS_NAME,)),
            None,
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
    except GLib.Error as exc:
        # Watcher may want the object path instead of the bus name.
        try:
            connection.call_sync(
                WATCHER_NAME,
                WATCHER_PATH,
                WATCHER_IFACE,
                "RegisterStatusNotifierItem",
                GLib.Variant("(s)", (OBJECT_PATH,)),
                None,
                Gio.DBusCallFlags.NONE,
                -1,
                None,
            )
        except GLib.Error:
            print(f"[network-applet] tray watcher unavailable: {exc}", file=sys.stderr)


def on_bus_acquired(connection: Gio.DBusConnection, _name: str) -> None:
    node = Gio.DBusNodeInfo.new_for_xml(INTROSPECTION_XML)
    connection.register_object(
        OBJECT_PATH,
        node.interfaces[0],
        on_method_call,
        on_get_property,
        None,
    )
    register_with_watcher(connection)


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
