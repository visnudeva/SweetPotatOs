#!/usr/bin/env python3
"""Native GTK3 System panel for SweetPotatOs Settings.

Sub-tabs: Wi-Fi (nmcli), Bluetooth (bluetoothctl), Sound (pactl), Displays.
All blocking probes run on worker threads with timeouts and marshal back via
GLib.idle_add so the Settings window never freezes.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk  # noqa: E402


def _run(cmd: list[str], timeout: float = 5.0) -> tuple[int, str, str]:
    try:
        res = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        return res.returncode, res.stdout, res.stderr
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, "", str(exc)


def _bg(fn, on_done=None):
    def worker():
        result = fn()
        if on_done is not None:
            GLib.idle_add(on_done, result)

    threading.Thread(target=worker, daemon=True).start()


def _clear(box: Gtk.Container):
    for child in list(box.get_children()):
        box.remove(child)


def _scrolled(child: Gtk.Widget) -> Gtk.ScrolledWindow:
    sc = Gtk.ScrolledWindow()
    sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    sc.set_hexpand(True)
    sc.set_vexpand(True)
    sc.add(child)
    return sc


class WifiTab(Gtk.Box):
    def __init__(self, on_advanced):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self._busy = False
        self._setting = False

        top = Gtk.Box(spacing=8)
        lbl = Gtk.Label(label="Wi-Fi")
        lbl.set_name("section")
        lbl.set_xalign(0)
        top.pack_start(lbl, True, True, 0)

        self._scan_btn = Gtk.Button.new_with_label("Scan")
        self._scan_btn.connect("clicked", lambda *_: self.refresh(rescan=True))
        top.pack_start(self._scan_btn, False, False, 0)

        self._sw = Gtk.Switch()
        self._sw.set_valign(Gtk.Align.CENTER)
        self._sw.connect("notify::active", self._on_toggle)
        top.pack_start(self._sw, False, False, 0)
        self.pack_start(top, False, False, 0)

        self._status = Gtk.Label(label="")
        self._status.set_name("muted")
        self._status.set_xalign(0)
        self.pack_start(self._status, False, False, 0)

        self._list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.pack_start(_scrolled(self._list), True, True, 0)

        adv = Gtk.Button.new_with_label("Network menu")
        adv.set_halign(Gtk.Align.END)
        adv.connect("clicked", on_advanced)
        self.pack_start(adv, False, False, 0)

    def _on_toggle(self, sw, _pspec):
        if self._setting:
            return
        state = "on" if sw.get_active() else "off"
        self._status.set_text(f"Turning Wi-Fi {state}…")
        _bg(
            lambda: _run(["nmcli", "radio", "wifi", state], timeout=6),
            lambda _: self.refresh(rescan=(state == "on")),
        )

    def refresh(self, rescan: bool = False):
        if self._busy:
            return
        if not shutil.which("nmcli"):
            self._status.set_text("nmcli (NetworkManager) is not installed.")
            return
        self._busy = True
        self._scan_btn.set_sensitive(False)
        if rescan:
            self._status.set_text("Scanning…")

        def probe():
            _, radio_out, _ = _run(["nmcli", "radio", "wifi"], timeout=4)
            enabled = radio_out.strip().lower() == "enabled"
            if not enabled:
                return (False, [], set())
            _, con_out, _ = _run(["nmcli", "-t", "-f", "NAME", "con", "show"], timeout=4)
            saved = {line.strip() for line in con_out.splitlines() if line.strip()}
            args = [
                "nmcli",
                "-t",
                "-f",
                "IN-USE,SSID,SIGNAL,SECURITY",
                "dev",
                "wifi",
                "list",
                "--rescan",
                "yes" if rescan else "no",
            ]
            _, out, _ = _run(args, timeout=10 if rescan else 5)
            by_ssid = {}
            for raw in out.splitlines():
                parts = raw.split(":")
                if len(parts) < 4:
                    continue
                in_use = parts[0].strip() == "*"
                ssid = parts[1].strip()
                if not ssid:
                    continue
                try:
                    sig = int(parts[2].strip() or "0")
                except ValueError:
                    sig = 0
                sec = ":".join(parts[3:]).strip()
                cur = by_ssid.get(ssid)
                if cur is None or in_use or (not cur["active"] and sig > cur["signal"]):
                    by_ssid[ssid] = {
                        "ssid": ssid,
                        "active": in_use,
                        "signal": sig,
                        "secured": bool(sec and sec != "--"),
                    }
            nets = sorted(
                by_ssid.values(),
                key=lambda n: (not n["active"], -n["signal"], n["ssid"].lower()),
            )
            return (True, nets, saved)

        def done(data):
            self._busy = False
            self._scan_btn.set_sensitive(True)
            enabled, nets, saved = data
            self._setting = True
            self._sw.set_active(enabled)
            self._setting = False
            _clear(self._list)
            if not enabled:
                self._status.set_text("Wi-Fi is off.")
                self._list.show_all()
                return
            if not nets:
                self._status.set_text("No networks found.")
                self._list.show_all()
                return
            active_net = next((n["ssid"] for n in nets if n["active"]), None)
            self._status.set_text(
                f"Connected to {active_net}" if active_net else f"{len(nets)} networks"
            )
            for net in nets:
                row = Gtk.Box(spacing=8)
                lock = " · lock" if net["secured"] else ""
                tag = " (connected)" if net["active"] else ""
                name = Gtk.Label(label=f"{net['ssid']}{tag}")
                name.set_xalign(0)
                name.set_hexpand(True)
                info = Gtk.Label(label=f"{net['signal']}%{lock}")
                info.set_name("muted")
                row.pack_start(name, True, True, 0)
                row.pack_start(info, False, False, 0)
                if net["active"]:
                    btn = Gtk.Button.new_with_label("Disconnect")
                    btn.connect("clicked", lambda _b, s=net["ssid"]: self._disconnect(s))
                else:
                    btn = Gtk.Button.new_with_label("Connect")
                    is_saved = net["ssid"] in saved
                    btn.connect(
                        "clicked",
                        lambda _b, n=net, sv=is_saved: self._connect(n, sv),
                    )
                row.pack_start(btn, False, False, 0)
                self._list.pack_start(row, False, False, 0)
            self._list.show_all()

        _bg(probe, done)

    def _disconnect(self, ssid: str):
        self._status.set_text(f"Disconnecting {ssid}…")
        _bg(
            lambda: _run(["nmcli", "con", "down", ssid], timeout=8),
            lambda _: self.refresh(rescan=False),
        )

    def _connect(self, net: dict, is_saved: bool):
        ssid = net["ssid"]
        password = None
        if net["secured"] and not is_saved:
            password = self._ask_password(ssid)
            if password is None:
                return
        self._status.set_text(f"Connecting to {ssid}…")

        def work():
            if is_saved:
                rc, _, err = _run(["nmcli", "con", "up", ssid], timeout=15)
                if rc == 0:
                    return (0, "")
            cmd = ["nmcli", "dev", "wifi", "connect", ssid]
            if password is not None:
                cmd += ["password", password]
            rc, _, err = _run(cmd, timeout=20)
            return (rc, err.strip())

        def done(res):
            rc, err = res
            if rc != 0:
                self._status.set_text(err or f"Could not connect to {ssid}.")
            self.refresh(rescan=False)

        _bg(work, done)

    def _ask_password(self, ssid: str) -> str | None:
        dlg = Gtk.Dialog(
            title=f"Connect to {ssid}",
            transient_for=self.get_toplevel() if isinstance(self.get_toplevel(), Gtk.Window) else None,
            modal=True,
        )
        dlg.add_buttons(
            Gtk.STOCK_CANCEL,
            Gtk.ResponseType.CANCEL,
            "Connect",
            Gtk.ResponseType.OK,
        )
        dlg.set_default_response(Gtk.ResponseType.OK)
        area = dlg.get_content_area()
        area.set_spacing(8)
        area.set_margin_top(12)
        area.set_margin_bottom(12)
        area.set_margin_start(12)
        area.set_margin_end(12)
        lbl = Gtk.Label(label=f"Password for {ssid}:")
        lbl.set_xalign(0)
        entry = Gtk.Entry()
        entry.set_visibility(False)
        entry.set_activates_default(True)
        area.pack_start(lbl, False, False, 0)
        area.pack_start(entry, False, False, 0)
        dlg.show_all()
        resp = dlg.run()
        pw = entry.get_text() if resp == Gtk.ResponseType.OK else None
        dlg.destroy()
        return pw


class BluetoothTab(Gtk.Box):
    def __init__(self, on_advanced):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self._busy = False
        self._setting = False

        top = Gtk.Box(spacing=8)
        lbl = Gtk.Label(label="Bluetooth")
        lbl.set_name("section")
        lbl.set_xalign(0)
        top.pack_start(lbl, True, True, 0)

        self._scan_btn = Gtk.Button.new_with_label("Scan")
        self._scan_btn.connect("clicked", lambda *_: self._scan())
        top.pack_start(self._scan_btn, False, False, 0)

        self._sw = Gtk.Switch()
        self._sw.set_valign(Gtk.Align.CENTER)
        self._sw.connect("notify::active", self._on_toggle)
        top.pack_start(self._sw, False, False, 0)
        self.pack_start(top, False, False, 0)

        self._status = Gtk.Label(label="")
        self._status.set_name("muted")
        self._status.set_xalign(0)
        self.pack_start(self._status, False, False, 0)

        self._list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.pack_start(_scrolled(self._list), True, True, 0)

        adv = Gtk.Button.new_with_label("Advanced (Blueman)")
        adv.set_halign(Gtk.Align.END)
        adv.connect("clicked", on_advanced)
        self.pack_start(adv, False, False, 0)

    def _on_toggle(self, sw, _pspec):
        if self._setting:
            return
        state = "on" if sw.get_active() else "off"
        self._status.set_text(f"Turning Bluetooth {state}…")

        def work():
            if state == "on" and shutil.which("rfkill"):
                _run(["rfkill", "unblock", "bluetooth"], timeout=3)
            return _run(["bluetoothctl", "power", state], timeout=6)

        _bg(work, lambda _: self.refresh())

    def _scan(self):
        if not shutil.which("bluetoothctl"):
            return
        self._scan_btn.set_sensitive(False)
        self._status.set_text("Scanning (5s)…")

        def work():
            return _run(["bluetoothctl", "--timeout", "5", "scan", "on"], timeout=8)

        def done(_):
            self._scan_btn.set_sensitive(True)
            self.refresh()

        _bg(work, done)

    def refresh(self):
        if self._busy:
            return
        if not shutil.which("bluetoothctl"):
            self._status.set_text("bluetoothctl is not installed.")
            return
        self._busy = True

        def probe():
            rc, show_out, _ = _run(["bluetoothctl", "show"], timeout=4)
            if rc != 0 or not show_out.strip():
                return (False, False, [])
            powered = "Powered: yes" in show_out
            if not powered:
                return (True, False, [])
            _, dev_out, _ = _run(["bluetoothctl", "devices"], timeout=4)
            _, conn_out, _ = _run(["bluetoothctl", "devices", "Connected"], timeout=4)
            connected_macs = set()
            for line in conn_out.splitlines():
                m = re.match(r"^Device\s+([0-9A-Fa-f:]{17})\s+", line.strip())
                if m:
                    connected_macs.add(m.group(1))
            devices = []
            for line in dev_out.splitlines():
                m = re.match(r"^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$", line.strip())
                if m:
                    mac, name = m.group(1), m.group(2).strip()
                    devices.append(
                        {
                            "mac": mac,
                            "name": name,
                            "connected": mac in connected_macs,
                        }
                    )
            devices.sort(key=lambda d: (not d["connected"], d["name"].lower()))
            return (True, True, devices)

        def done(data):
            self._busy = False
            has_adapter, powered, devices = data
            self._setting = True
            self._sw.set_active(powered)
            self._setting = False
            _clear(self._list)
            if not has_adapter:
                self._status.set_text("No Bluetooth adapter found.")
                self._list.show_all()
                return
            if not powered:
                self._status.set_text("Bluetooth is off.")
                self._list.show_all()
                return
            conn_count = sum(1 for d in devices if d["connected"])
            self._status.set_text(
                f"{conn_count} connected" if conn_count else f"{len(devices)} devices"
            )
            for dev in devices:
                row = Gtk.Box(spacing=8)
                tag = " (connected)" if dev["connected"] else ""
                lbl = Gtk.Label(label=f"{dev['name']}{tag}")
                lbl.set_xalign(0)
                lbl.set_hexpand(True)
                row.pack_start(lbl, True, True, 0)
                if dev["connected"]:
                    btn = Gtk.Button.new_with_label("Disconnect")
                    btn.connect("clicked", lambda _b, d=dev: self._act("disconnect", d))
                else:
                    btn = Gtk.Button.new_with_label("Connect")
                    btn.connect("clicked", lambda _b, d=dev: self._act("connect", d))
                row.pack_start(btn, False, False, 0)
                self._list.pack_start(row, False, False, 0)
            self._list.show_all()

        _bg(probe, done)

    def _act(self, action: str, dev: dict):
        verb = "Connecting" if action == "connect" else "Disconnecting"
        self._status.set_text(f"{verb} {dev['name']}…")
        _bg(
            lambda: _run(["bluetoothctl", action, dev["mac"]], timeout=12),
            lambda _: self.refresh(),
        )


class SoundTab(Gtk.Box):
    def __init__(self, on_advanced):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self._setting = False
        self._sinks: list[tuple[str, str]] = []
        self._sources: list[tuple[str, str]] = []

        self._status = Gtk.Label(label="")
        self._status.set_name("muted")
        self._status.set_xalign(0)
        self.pack_start(self._status, False, False, 0)

        out_lbl = Gtk.Label(label="Output")
        out_lbl.set_name("section")
        out_lbl.set_xalign(0)
        self.pack_start(out_lbl, False, False, 0)

        self._sink_combo = Gtk.ComboBoxText()
        self._sink_combo.connect("changed", self._on_sink_changed)
        self.pack_start(self._sink_combo, False, False, 0)

        out_row = Gtk.Box(spacing=8)
        self._out_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 150, 1)
        self._out_scale.set_draw_value(True)
        self._out_scale.set_value_pos(Gtk.PositionType.RIGHT)
        self._out_scale.set_hexpand(True)
        self._out_scale.connect("value-changed", self._on_out_vol)
        self._out_mute = Gtk.ToggleButton.new_with_label("Mute")
        self._out_mute.connect("toggled", self._on_out_mute)
        out_row.pack_start(self._out_scale, True, True, 0)
        out_row.pack_start(self._out_mute, False, False, 0)
        self.pack_start(out_row, False, False, 0)

        in_lbl = Gtk.Label(label="Input")
        in_lbl.set_name("section")
        in_lbl.set_xalign(0)
        self.pack_start(in_lbl, False, False, 0)

        self._src_combo = Gtk.ComboBoxText()
        self._src_combo.connect("changed", self._on_src_changed)
        self.pack_start(self._src_combo, False, False, 0)

        in_row = Gtk.Box(spacing=8)
        self._in_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self._in_scale.set_draw_value(True)
        self._in_scale.set_value_pos(Gtk.PositionType.RIGHT)
        self._in_scale.set_hexpand(True)
        self._in_scale.connect("value-changed", self._on_in_vol)
        self._in_mute = Gtk.ToggleButton.new_with_label("Mute")
        self._in_mute.connect("toggled", self._on_in_mute)
        in_row.pack_start(self._in_scale, True, True, 0)
        in_row.pack_start(self._in_mute, False, False, 0)
        self.pack_start(in_row, False, False, 0)

        adv = Gtk.Button.new_with_label("Advanced (pavucontrol)")
        adv.set_halign(Gtk.Align.END)
        adv.connect("clicked", on_advanced)
        self.pack_end(adv, False, False, 0)

    def _parse_pct(self, text: str) -> int:
        m = re.search(r"(\d+)%", text)
        return int(m.group(1)) if m else 0

    def refresh(self):
        if not shutil.which("pactl"):
            self._status.set_text("pactl is not installed.")
            return

        def probe():
            _, def_sink, _ = _run(["pactl", "get-default-sink"], timeout=3)
            _, def_src, _ = _run(["pactl", "get-default-source"], timeout=3)
            _, out_vol, _ = _run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"], timeout=3)
            _, out_mute, _ = _run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"], timeout=3)
            _, in_vol, _ = _run(["pactl", "get-source-volume", "@DEFAULT_SOURCE@"], timeout=3)
            _, in_mute, _ = _run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"], timeout=3)

            sinks = self._list_devices("sinks")
            sources = [
                (n, d) for n, d in self._list_devices("sources") if not n.endswith(".monitor")
            ]
            return (
                def_sink.strip(),
                def_src.strip(),
                self._parse_pct(out_vol),
                "yes" in out_mute.lower(),
                self._parse_pct(in_vol),
                "yes" in in_mute.lower(),
                sinks,
                sources,
            )

        def done(data):
            def_sink, def_src, ovol, omute, ivol, imute, sinks, sources = data
            self._setting = True
            self._sinks = sinks
            self._sources = sources
            self._sink_combo.remove_all()
            active_sink = 0
            for i, (name, desc) in enumerate(sinks):
                self._sink_combo.append_text(desc)
                if name == def_sink:
                    active_sink = i
            if sinks:
                self._sink_combo.set_active(active_sink)

            self._src_combo.remove_all()
            active_src = 0
            for i, (name, desc) in enumerate(sources):
                self._src_combo.append_text(desc)
                if name == def_src:
                    active_src = i
            if sources:
                self._src_combo.set_active(active_src)

            self._out_scale.set_value(min(150, max(0, ovol)))
            self._out_mute.set_active(omute)
            self._in_scale.set_value(min(100, max(0, ivol)))
            self._in_mute.set_active(imute)
            self._status.set_text("")
            self._setting = False

        _bg(probe, done)

    def _list_devices(self, kind: str) -> list[tuple[str, str]]:
        rc, out, _ = _run(["pactl", "-f", "json", "list", kind], timeout=4)
        if rc == 0 and out.strip():
            try:
                items = json.loads(out)
                return [
                    (it.get("name", ""), it.get("description") or it.get("name", ""))
                    for it in items
                    if it.get("name")
                ]
            except json.JSONDecodeError:
                pass
        _, short, _ = _run(["pactl", "list", "short", kind], timeout=4)
        res = []
        for line in short.splitlines():
            parts = line.split("\t")
            if len(parts) >= 2:
                res.append((parts[1], parts[1]))
        return res

    def _on_sink_changed(self, combo):
        if self._setting:
            return
        idx = combo.get_active()
        if 0 <= idx < len(self._sinks):
            name = self._sinks[idx][0]
            _bg(lambda: _run(["pactl", "set-default-sink", name], timeout=3))

    def _on_src_changed(self, combo):
        if self._setting:
            return
        idx = combo.get_active()
        if 0 <= idx < len(self._sources):
            name = self._sources[idx][0]
            _bg(lambda: _run(["pactl", "set-default-source", name], timeout=3))

    def _on_out_vol(self, scale):
        if self._setting:
            return
        val = int(round(scale.get_value()))
        _bg(lambda: _run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{val}%"], timeout=3))

    def _on_out_mute(self, btn):
        if self._setting:
            return
        val = "1" if btn.get_active() else "0"
        _bg(lambda: _run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", val], timeout=3))

    def _on_in_vol(self, scale):
        if self._setting:
            return
        val = int(round(scale.get_value()))
        _bg(lambda: _run(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", f"{val}%"], timeout=3))

    def _on_in_mute(self, btn):
        if self._setting:
            return
        val = "1" if btn.get_active() else "0"
        _bg(lambda: _run(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", val], timeout=3))


class DisplaysTab(Gtk.Box):
    def __init__(self, on_open_displays):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        lbl = Gtk.Label(label="Displays")
        lbl.set_name("section")
        lbl.set_xalign(0)
        self.pack_start(lbl, False, False, 0)

        self._list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.pack_start(_scrolled(self._list), True, True, 0)

        btn = Gtk.Button.new_with_label("Arrange displays")
        btn.set_halign(Gtk.Align.END)
        btn.connect("clicked", on_open_displays)
        self.pack_start(btn, False, False, 0)

    def refresh(self):
        def probe():
            if not shutil.which("swaymsg"):
                return []
            rc, out, _ = _run(["swaymsg", "-t", "get_outputs"], timeout=3)
            if rc != 0:
                return []
            try:
                return json.loads(out)
            except json.JSONDecodeError:
                return []

        def done(outputs):
            _clear(self._list)
            if not outputs:
                lbl = Gtk.Label(label="Open nwg-displays to configure monitors.")
                lbl.set_name("muted")
                lbl.set_xalign(0)
                self._list.pack_start(lbl, False, False, 0)
            else:
                for out in outputs:
                    name = out.get("name", "?")
                    mode = out.get("current_mode") or {}
                    w, h = mode.get("width", 0), mode.get("height", 0)
                    hz = round((mode.get("refresh", 0) or 0) / 1000)
                    scale = out.get("scale", 1)
                    active = out.get("active", False)
                    detail = f"{w}×{h} @ {hz}Hz · scale {scale}" if active and w else "disabled"
                    row = Gtk.Label(label=f"{name}  —  {detail}")
                    row.set_xalign(0)
                    self._list.pack_start(row, False, False, 0)
            self._list.show_all()

        _bg(probe, done)


class SystemPanel(Gtk.Box):
    """Native System hub page: Wi-Fi, Bluetooth, Sound, Displays."""

    def __init__(self, on_displays, on_sound_adv, on_wifi_adv, on_bt_adv):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.set_hexpand(True)
        self.set_vexpand(True)

        self._stack = Gtk.Stack()
        self._stack.set_transition_type(Gtk.StackTransitionType.NONE)
        self._stack.set_hexpand(True)
        self._stack.set_vexpand(True)

        self._wifi = WifiTab(on_wifi_adv)
        self._bt = BluetoothTab(on_bt_adv)
        self._sound = SoundTab(on_sound_adv)
        self._displays = DisplaysTab(on_displays)

        self._stack.add_titled(self._wifi, "wifi", "Wi-Fi")
        self._stack.add_titled(self._bt, "bluetooth", "Bluetooth")
        self._stack.add_titled(self._sound, "sound", "Sound")
        self._stack.add_titled(self._displays, "displays", "Displays")

        switcher = Gtk.StackSwitcher()
        switcher.set_stack(self._stack)
        switcher.set_halign(Gtk.Align.START)
        self.pack_start(switcher, False, False, 0)
        self.pack_start(self._stack, True, True, 0)

        self._stack.connect("notify::visible-child-name", self._on_sub_changed)

    def _on_sub_changed(self, *_args):
        self.refresh_active()

    def refresh_active(self):
        name = self._stack.get_visible_child_name() or "wifi"
        if name == "wifi":
            self._wifi.refresh(rescan=False)
        elif name == "bluetooth":
            self._bt.refresh()
        elif name == "sound":
            self._sound.refresh()
        elif name == "displays":
            self._displays.refresh()
