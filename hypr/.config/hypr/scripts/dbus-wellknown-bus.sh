#!/bin/sh
# Expose the session D-Bus at the well-known path $XDG_RUNTIME_DIR/bus.
#
# Hyprland is started via `dbus-run-session` (~/.bash_profile), which places the
# session bus at a random /tmp/dbus-XXXXXX path. Apps launched OUTSIDE that
# environment — stray terminals, IDEs, or launchers whose process reparents to
# init — don't inherit DBUS_SESSION_BUS_ADDRESS and, on this OpenRC/elogind
# system, there's no systemd user bus at the standard socket. Such apps then
# fall back to a PRIVATE bus, which hides their MPRIS interface (e.g. the
# Gravity-Music player) from Waybar/playerctl.
#
# Symlinking the standard socket fixes it for every app: libdbus/GDBus default
# to $XDG_RUNTIME_DIR/bus when DBUS_SESSION_BUS_ADDRESS is unset, and the
# Gravity-Music launcher explicitly tests for this socket before falling back.
[ -n "$DBUS_SESSION_BUS_ADDRESS" ] || exit 0
sock=${DBUS_SESSION_BUS_ADDRESS#unix:path=}
sock=${sock%%,*}
target="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
# If the bus already lives at the well-known socket (e.g. it was started there by
# /usr/local/bin/hypr-session), there is nothing to do — and linking it to itself
# would DELETE the live socket via `ln -sfn`. Only link a real, *different* path.
case "$sock" in
  /*) [ -S "$sock" ] && [ "$sock" != "$target" ] && ln -sfn "$sock" "$target" ;;
esac
