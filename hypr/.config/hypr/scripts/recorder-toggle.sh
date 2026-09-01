#!/bin/bash
# Toggle wf-recorder. First press: pick region + start. Second press: stop & save.
set -euo pipefail

OUT_DIR="${HOME}/Videos/Recordings"
PIDFILE="/tmp/wf-recorder-${USER}.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  pid=$(cat "$PIDFILE")
  kill -SIGINT "$pid" || true
  rm -f "$PIDFILE"
  notify-send "Screen Recorder" "Recording stopped" -i media-record
  exit 0
fi

mkdir -p "$OUT_DIR"
ts=$(date +%Y%m%d-%H%M%S)
out="${OUT_DIR}/rec-${ts}.mp4"

geom=$(slurp -d 2>/dev/null) || { notify-send "Screen Recorder" "Cancelled"; exit 0; }

notify-send "Screen Recorder" "Recording started\n$out" -i media-record

wf-recorder -g "$geom" -f "$out" --audio=auto >/dev/null 2>&1 &
echo $! > "$PIDFILE"
