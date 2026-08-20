#!/usr/bin/env bash
# Ensure nwg-displays / sway include paths exist before Swirl parses config.
set -euo pipefail

dir="${HOME}/.config/sway"
mkdir -p "${dir}"
[[ -f "${dir}/outputs" ]] || install -m644 /dev/null "${dir}/outputs"
[[ -f "${dir}/workspaces" ]] || install -m644 /dev/null "${dir}/workspaces"
