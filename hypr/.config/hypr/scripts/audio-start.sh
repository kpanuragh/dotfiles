#!/bin/sh
# audio-start.sh — start & supervise the PipeWire audio stack for Hyprland.
# OpenRC/elogind has no systemd --user units, so we supervise here.
# Launched from hyprland.lua autostart. Single-instance (flock); each component
# is guarded by pgrep so running this while the stack is already up is harmless,
# and each is respawned if it dies.

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
sock="$XDG_RUNTIME_DIR/pipewire-0"

# only one supervisor at a time
LOCK="$XDG_RUNTIME_DIR/audio-start.lock"
exec 9>"$LOCK" 2>/dev/null || exit 0
if command -v flock >/dev/null 2>&1; then flock -n 9 || exit 0; fi

# pipewire core
( while :; do pgrep -x pipewire >/dev/null 2>&1 || pipewire; sleep 2; done ) &
# pulse shim (needs the pipewire socket)
( while :; do [ -S "$sock" ] && { pgrep -x pipewire-pulse >/dev/null 2>&1 || pipewire-pulse; }; sleep 2; done ) &
# session manager
( while :; do [ -S "$sock" ] && { pgrep -x wireplumber >/dev/null 2>&1 || wireplumber; }; sleep 2; done ) &

wait   # hold the flock for the supervisor's lifetime
