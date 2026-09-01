#!/usr/bin/env bash
# Re-apply per-output state whenever a monitor is connected.
#
# Why this exists:
#   waybar and hyprpaper bind their surfaces to the outputs that exist when
#   they start (Hyprland autostart). A monitor that appears LATER — replug, or
#   one that initialises slowly at boot — gets no wallpaper and no waybar and
#   shows a black screen. Hyprland reapplies the `monitor` rule on reconnect,
#   but the two daemons need a nudge. We listen on the Hyprland event socket
#   (.socket2.sock) and, on every monitor-added event, re-paint wallpapers and
#   reload waybar so it recreates its bars on all current outputs.
#
#   socat/nc are not installed on this host, so the socket is streamed with a
#   tiny python3 reader (python3 is already a dependency of the wallpaper
#   scripts). The listener auto-reconnects if Hyprland restarts the socket.
set -uo pipefail

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
[ -n "$SIG" ] || { echo "monitor-hotplug: HYPRLAND_INSTANCE_SIGNATURE unset" >&2; exit 1; }
SOCK="${XDG_RUNTIME_DIR}/hypr/${SIG}/.socket2.sock"
INIT="${HOME}/.config/hypr/scripts/wallpaper-init.sh"
LOG="${XDG_RUNTIME_DIR}/hypr/${SIG}/monitor-hotplug.log"

log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >>"$LOG"; }

# React to a monitor-added event: debounce, let Hyprland finish applying the
# monitor rule, then re-paint wallpaper everywhere and rebind waybar.
react() {
  log "monitor added -> re-applying wallpaper + reloading waybar"
  sleep 1                       # let Hyprland settle the new output + its rule
  "$INIT" >>"$LOG" 2>&1 || log "wallpaper-init failed"
  # SIGUSR2 makes waybar reload and recreate its bars on every current output.
  if pkill -SIGUSR2 -x waybar 2>/dev/null; then
    log "waybar reloaded"
  else
    log "waybar not running -> launching"
    waybar >>"$LOG" 2>&1 &
  fi
}

stream_events() {
  # Print newline-delimited Hyprland events from the v2 event socket.
  python3 -u -c '
import os, socket, sys
sock = sys.argv[1]
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sock)
buf = b""
while True:
    data = s.recv(4096)
    if not data:
        break
    buf += data
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        sys.stdout.write(line.decode("utf-8", "replace") + "\n")
        sys.stdout.flush()
' "$SOCK"
}

log "listener started (sock=$SOCK)"
# Outer loop: reconnect if the socket goes away (e.g. hyprctl reload).
while :; do
  if [ ! -S "$SOCK" ]; then sleep 1; continue; fi
  last=0
  stream_events | while IFS= read -r line; do
    case "$line" in
      monitoradded*)            # matches monitoradded>> and monitoraddedv2>>
        # A single hotplug fires both monitoradded and monitoraddedv2; coalesce
        # them (and any rapid replug bounce) so we only react once per ~3s.
        now=$(date +%s)
        [ $(( now - last )) -lt 3 ] && continue
        react
        last=$(date +%s)
        ;;
    esac
  done
  log "event stream ended -> reconnecting"
  sleep 1
done
