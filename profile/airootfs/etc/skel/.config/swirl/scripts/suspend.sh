#!/usr/bin/env bash
# Sleep cleanly: drop leftover caffeine inhibitors, then suspend.
# Pair with swayidle after-resume so the panel comes back on wake.
set -euo pipefail

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

# Old caffeine used systemd-inhibit. Clear any leftover before sleep so
# some laptops do not stick in a state that will not wake.
if [[ -f "${pidfile}" ]]; then
  kill_tree "$(tr -d '[:space:]' < "${pidfile}" || true)"
fi
while read -r pid; do
  [[ -z "${pid}" || "${pid}" == "$$" || "${pid}" == "${BASHPID}" ]] && continue
  kill "${pid}" 2>/dev/null || true
done < <(pgrep -f 'systemd-inhibit --what=idle --who=SweetPotato' || true)

for _ in 1 2 3 4 5; do
  if ! systemd-inhibit --list --no-legend 2>/dev/null | grep -q 'Caffeine mode'; then
    break
  fi
  sleep 0.1
done

exec systemctl suspend
