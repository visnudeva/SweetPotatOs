#!/usr/bin/env bash
# SweetPotato screenshot (full or region) → ~/Pictures/Screenshots + clipboard + notify
set -euo pipefail

TAG="sweetpotato-screenshot"
OUTDIR="${HOME}/Pictures/Screenshots"
MODE="${1:-full}"

notify() {
  local icon="$1" title="$2" body="$3"
  notify-send -t 2500 -a "Screenshot" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" 2>/dev/null || true
}

mkdir -p "${OUTDIR}"
outfile="${OUTDIR}/$(date +%Y%m%d_%H%M%S).png"

case "${MODE}" in
  region)
    geom="$(slurp)" || {
      notify "dialog-error" "Screenshot" "Cancelled"
      exit 0
    }
    grim -g "${geom}" "${outfile}"
    ;;
  full|*)
    grim "${outfile}"
    ;;
esac

if command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "${outfile}"
fi

notify "camera-photo" "Screenshot" "Saved to ${outfile##*/}"
