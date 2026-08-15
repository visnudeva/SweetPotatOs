#!/usr/bin/env bash
# SweetPotato screen record toggle (wf-recorder) + mako notification
set -euo pipefail

TAG="sweetpotato-record"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-wf-recorder.pid"
OUTDIR="${HOME}/Videos"

notify() {
  local icon="$1" title="$2" body="$3"
  notify-send -t 2500 -a "Screen record" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}"
}

is_recording() {
  [[ -f "${PIDFILE}" ]] || return 1
  local pid
  pid="$(<"${PIDFILE}")"
  kill -0 "${pid}" 2>/dev/null
}

stop_recording() {
  local pid
  pid="$(<"${PIDFILE}")"
  # SIGINT lets wf-recorder finalize the file cleanly
  kill -INT "${pid}" 2>/dev/null || true
  for _ in $(seq 1 50); do
    kill -0 "${pid}" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "${PIDFILE}"
  notify "media-playback-stop" "Screen record" "Saved to ~/Videos"
}

start_recording() {
  local geom outfile
  mkdir -p "${OUTDIR}"
  geom="$(slurp)" || {
    notify "dialog-error" "Screen record" "Cancelled"
    exit 0
  }
  outfile="${OUTDIR}/rec_$(date +%Y%m%d_%H%M%S).mp4"
  wf-recorder -g "${geom}" -a -f "${outfile}" &
  echo $! > "${PIDFILE}"
  notify "media-record" "Screen record" "Recording… press Mod+Print to stop"
}

if is_recording; then
  stop_recording
else
  # Drop a stale pidfile if the process already died
  rm -f "${PIDFILE}"
  start_recording
fi
