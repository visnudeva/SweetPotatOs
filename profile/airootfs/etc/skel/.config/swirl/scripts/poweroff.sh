#!/bin/bash
# Drop caffeine before cutting power. An idle lock left running can stop
# the machine with the power light still on, and it will not wake.
runtime="${XDG_RUNTIME_DIR:-/tmp}"
pidfile="${runtime}/sweetpotato-caffeine.pid"

kill_tree() {
  local pid="$1" child
  [[ -n "${pid}" && "${pid}" != 0 ]] || return 0
  for child in $(pgrep -P "${pid}" 2>/dev/null || true); do
    kill_tree "${child}"
  done
  kill "${pid}" 2>/dev/null || true
}

if [[ -f "${pidfile}" ]]; then
  kill_tree "$(<"${pidfile}")"
fi
rm -f "${pidfile}" "${runtime}/sweetpotato-caffeine.state"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if ! systemd-inhibit --list --no-legend 2>/dev/null | grep -q 'Caffeine mode'; then
    break
  fi
  sleep 0.1
done
exec systemctl poweroff --ignore-inhibitors
