#!/usr/bin/env bash
# Turn numbered workspace buttons into discs on the bar.
#
# swaybar draws the workspace name. A name "N:●" plus strip_workspace_numbers
# shows only the disc, while "workspace number N" still matches N
# (the digits before the colon are the workspace number).
#
# Display rules in ~/.config/sway/workspaces must stay numeric
# ("workspace 1 output …"). nwg-displays saves the live name, so this
# script rewrites a dotted name back to the number after the GUI closes.

set -euo pipefail

dot=$'\u25cf'
ws_file="${HOME}/.config/sway/workspaces"

normalize_workspace_file() {
  [[ -f "${ws_file}" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  sed -E \
    -e 's/^([[:space:]]*workspace[[:space:]]+)"([0-9]+):[^"]+"/\1\2/' \
    -e 's/^([[:space:]]*workspace[[:space:]]+)([0-9]+):[^[:space:]]+/\1\2/' \
    "${ws_file}" >"${tmp}"
  if cmp -s "${ws_file}" "${tmp}"; then
    rm -f "${tmp}"
  else
    mv -f "${tmp}" "${ws_file}"
  fi
}

if [[ "${1:-}" == "--normalize-file" ]]; then
  normalize_workspace_file
  exit 0
fi

lock="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-workspace-dots.lock"
mkdir -p "$(dirname "${lock}")"
exec 9>"${lock}"
flock -n 9 || exit 0

rename_plain() {
  local name num
  command -v swaymsg >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0
  while IFS= read -r name; do
    [[ "${name}" =~ ^([0-9]+)$ ]] || continue
    num="${BASH_REMATCH[1]}"
    swaymsg "rename workspace number ${num} to ${num}:${dot}" >/dev/null 2>&1 || true
  done < <(swaymsg -t get_workspaces 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)
}

for _ in $(seq 1 25); do
  swaymsg -t get_version >/dev/null 2>&1 && break
  sleep 0.2
done

normalize_workspace_file
rename_plain

swaymsg -t subscribe -m '["workspace"]' 2>/dev/null | while IFS= read -r _; do
  rename_plain
done
