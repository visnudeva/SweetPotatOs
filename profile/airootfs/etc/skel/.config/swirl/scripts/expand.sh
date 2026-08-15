#!/usr/bin/env bash
# Toggle focused Swirl column: 50/50 pair ↔ full-width (100%).
# Uses set_size (strip layout), not compositor fullscreen (Mod+Shift+f).
set -euo pipefail

python3 - <<'PY'
import json, subprocess, sys


def sway(*args):
    return subprocess.check_output(["swaymsg", *args], text=True)


def sway_cmd(cmd):
    subprocess.check_call(
        ["swaymsg", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def iter_nodes(node):
    yield node
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key) or []:
            yield from iter_nodes(child)


def find_focused(tree):
    focused = [n for n in iter_nodes(tree) if n.get("focused")]
    return focused[-1] if focused else None


def workspace_of(node, tree):
    target = node["id"]

    def contains(n):
        if n.get("id") == target:
            return True
        for key in ("nodes", "floating_nodes"):
            for c in n.get(key) or []:
                if contains(c):
                    return True
        return False

    for n in iter_nodes(tree):
        if n.get("type") == "workspace" and contains(n):
            return n
    return None


def output_of(workspace, tree):
    wid = workspace["id"]

    def contains(n):
        if n.get("id") == wid:
            return True
        for key in ("nodes", "floating_nodes"):
            for c in n.get(key) or []:
                if contains(c):
                    return True
        return False

    for n in iter_nodes(tree):
        if n.get("type") == "output" and contains(n):
            return n
    return None


def top_columns(workspace):
    return [n for n in (workspace.get("nodes") or []) if n.get("type") != "floating_con"]


def first_view_id(column):
    leaves = []
    for n in iter_nodes(column):
        if n.get("id") == column.get("id"):
            continue
        kids = n.get("nodes") or []
        if not kids and (n.get("app_id") or n.get("window") or n.get("pid") or n.get("name")):
            leaves.append(n)
    if leaves:
        return leaves[-1]["id"]
    # last resort: any non-column descendant leaf
    for n in iter_nodes(column):
        if n.get("id") != column.get("id") and not (n.get("nodes") or []):
            return n["id"]
    return column["id"]


def set_width(con_id, fraction):
    sway_cmd(f"[con_id={con_id}] set_size h {fraction}")


def apply_pair_layout(columns):
    n = len(columns)
    if n == 0:
        return
    for i, col in enumerate(columns, start=1):
        vid = first_view_id(col)
        if (n % 2 == 1) and i == n:
            set_width(vid, 1.0)
        else:
            set_width(vid, 0.5)


def width_frac(column, output):
    ow = (output.get("rect") or {}).get("width") or 0
    cw = (column.get("rect") or {}).get("width") or 0
    if ow <= 0:
        return 0.0
    return cw / ow


tree = json.loads(sway("-t", "get_tree"))
focused = find_focused(tree)
if not focused:
    sys.exit(0)

ws = workspace_of(focused, tree)
if not ws:
    sys.exit(0)

columns = top_columns(ws)
if not columns:
    sys.exit(0)

if len(columns) == 1:
    set_width(first_view_id(columns[0]), 1.0)
    sys.exit(0)

focus_col = None
for col in columns:
    ids = {n["id"] for n in iter_nodes(col)}
    if focused["id"] in ids:
        focus_col = col
        break
if focus_col is None:
    focus_col = columns[0]

output = output_of(ws, tree)
frac = width_frac(focus_col, output) if output else 0.0

# Already ~full → restore pair layout; else expand focused column.
if frac >= 0.85:
    apply_pair_layout(columns)
else:
    set_width(first_view_id(focus_col), 1.0)
PY
