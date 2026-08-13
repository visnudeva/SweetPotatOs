#!/usr/bin/env bash
# FSB100 — fullscreen media → 100% backlight, restore on exit.
# Usage: fsb100.sh [on|off|toggle]  (default: toggle)
set -euo pipefail

TAG="sweetpotato-fsb100"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-fsb100.pid"
STATEFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-fsb100.state"
SAVEDFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-fsb100.saved"

notify() {
  local icon="$1" title="$2" body="$3"
  notify-send -t 2500 -a "FSB100" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" 2>/dev/null || true
}

is_active() {
  [[ -f "${STATEFILE}" ]] && [[ "$(<"${STATEFILE}")" == "on" ]]
}

watch_alive() {
  [[ -f "${PIDFILE}" ]] || return 1
  kill -0 "$(<"${PIDFILE}")" 2>/dev/null
}

restore_if_saved() {
  if [[ -f "${SAVEDFILE}" ]]; then
    local saved
    saved="$(<"${SAVEDFILE}")"
    rm -f "${SAVEDFILE}"
    if [[ -n "${saved}" ]]; then
      brightnessctl set "${saved}%" >/dev/null 2>&1 || true
    fi
  fi
}

run_watch() {
  exec python3 - "${SAVEDFILE}" <<'PY'
import json, os, select, signal, subprocess, sys, time

SAVEDFILE = sys.argv[1]
MEDIA_CLASSES = (
    "vlc", "mpv", "celluloid", "totem", "smplayer", "gnome-mpv", "parole",
    "dragon", "kaffeine", "xine", "mplayer", "audacious", "clementine",
    "rhythmbox", "stremio", "jellyfin", "fladder", "plex", "kodi", "osmc",
    "firefox", "chrome", "chromium", "brave", "zen", "waterfox", "librewolf",
    "floorp", "swayimg",
)
TITLE_KEYWORDS = (
    "youtube", "vimeo", "netflix", "prime video", "disney", "hulu", "twitch",
    "video", "media", "vlc", "mpv", "watch", "play", "movie", "film",
    "stremio", "jellyfin", "plex", "kodi", "emby", "spotify", "tidal",
)

boosted = False
running = True


def brightness_pct():
    try:
        out = subprocess.check_output(["brightnessctl", "-m"], text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    parts = out.strip().split(",")
    if len(parts) < 4:
        return None
    return int(parts[3].rstrip("%"))


def set_brightness(pct):
    try:
        subprocess.check_call(
            ["brightnessctl", "set", f"{int(pct)}%"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass


def walk_focused(node):
    if node.get("focused"):
        return node
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key) or []:
            found = walk_focused(child)
            if found:
                return found
    return None


def focused_window():
    try:
        tree = json.loads(subprocess.check_output(["swaymsg", "-t", "get_tree"]))
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
        return None
    return walk_focused(tree)


def should_activate(win):
    if not win or not win.get("fullscreen_mode"):
        return False
    props = win.get("window_properties") or {}
    cls = (win.get("app_id") or props.get("class") or props.get("instance") or "").lower()
    title = (win.get("name") or props.get("title") or "").lower()
    if any(c in cls for c in MEDIA_CLASSES):
        return True
    return any(k in title for k in TITLE_KEYWORDS)


def enter_mode():
    global boosted
    if boosted:
        cur = brightness_pct()
        if cur is not None and cur < 99:
            set_brightness(100)
        return
    cur = brightness_pct()
    if cur is None:
        return
    with open(SAVEDFILE, "w") as fh:
        fh.write(str(cur))
    boosted = True
    if cur < 99:
        set_brightness(100)


def exit_mode():
    global boosted
    if not boosted:
        return
    boosted = False
    saved = None
    try:
        with open(SAVEDFILE) as fh:
            saved = fh.read().strip()
    except OSError:
        pass
    try:
        os.remove(SAVEDFILE)
    except OSError:
        pass
    if saved:
        set_brightness(saved)


def tick():
    enter_mode() if should_activate(focused_window()) else exit_mode()


def shutdown(*_args):
    global running
    running = False
    exit_mode()
    sys.exit(0)


signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)

proc = subprocess.Popen(
    ["swaymsg", "-t", "subscribe", "-m", '["window"]'],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)

tick()
last_poll = time.monotonic()
try:
    while running:
        line = ""
        if proc.stdout:
            ready, _, _ = select.select([proc.stdout], [], [], 1.0)
            if ready:
                line = proc.stdout.readline()
                if line == "" and proc.poll() is not None:
                    break
                tick()
        now = time.monotonic()
        if now - last_poll >= 1.0:
            last_poll = now
            tick()
        if proc.poll() is not None and not line:
            time.sleep(1.0)
            proc = subprocess.Popen(
                ["swaymsg", "-t", "subscribe", "-m", '["window"]'],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )
finally:
    if proc.poll() is None:
        proc.terminate()
    exit_mode()
PY
}

enable_fsb() {
  if is_active && watch_alive; then
    return 0
  fi
  if [[ -f "${PIDFILE}" ]]; then
    kill "$(<"${PIDFILE}")" 2>/dev/null || true
    rm -f "${PIDFILE}"
  fi
  if ! command -v brightnessctl >/dev/null 2>&1; then
    notify "dialog-warning" "FSB100" "brightnessctl not found"
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    notify "dialog-warning" "FSB100" "python3 not found"
    return 1
  fi
  "$0" watch >/dev/null 2>&1 &
  echo $! > "${PIDFILE}"
  echo "on" > "${STATEFILE}"
  notify "display-brightness-symbolic" "FSB100 on" "Fullscreen media → max brightness"
}

disable_fsb() {
  if [[ -f "${PIDFILE}" ]]; then
    kill "$(<"${PIDFILE}")" 2>/dev/null || true
    rm -f "${PIDFILE}"
  fi
  # Watcher restores on SIGTERM; belt-and-suspenders if it was already dead.
  sleep 0.05
  restore_if_saved
  echo "off" > "${STATEFILE}"
  notify "display-brightness-off-symbolic" "FSB100 off" "Brightness follows you again"
}

cmd="${1:-toggle}"
case "${cmd}" in
  watch)
    run_watch
    ;;
  on|enable)
    enable_fsb
    ;;
  off|disable)
    disable_fsb
    ;;
  toggle)
    if is_active && watch_alive; then
      disable_fsb
    else
      enable_fsb
    fi
    ;;
  *)
    echo "Usage: $(basename "$0") [on|off|toggle]" >&2
    exit 1
    ;;
esac
