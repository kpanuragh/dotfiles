#!/usr/bin/env python3
"""smart-gaps — remove gaps/border/rounding when the focused workspace has a
single tiled window, restore them otherwise. Listens to the Hyprland event
socket (.socket2.sock) so it reacts instantly without polling. Autostarted
from hyprland.lua. Restore values mirror the hl.config defaults
(gaps_out=12, gaps_in=6, border_size=2, rounding=10)."""
import json
import os
import socket
import subprocess

HIS = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
XDG = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SOCK = f"{XDG}/hypr/{HIS}/.socket2.sock"

# Events that can change the single-vs-many tiled count on the active workspace.
EVENTS = {b"openwindow", b"closewindow", b"movewindowv2", b"movewindow",
          b"workspacev2", b"workspace", b"focusedmon", b"changefloatingmode",
          b"fullscreen"}

_state = None  # True = currently in "single" (gapless) mode


def _hyprctl(*args, capture=False):
    return subprocess.run(["hyprctl", *args],
                          capture_output=capture, text=True,
                          stdout=None if capture else subprocess.DEVNULL,
                          stderr=None if capture else subprocess.DEVNULL)


def _active_ws():
    out = _hyprctl("activeworkspace", "-j", capture=True).stdout
    return json.loads(out)["id"]


def _tiled_count(ws_id):
    out = _hyprctl("clients", "-j", capture=True).stdout
    return sum(1 for c in json.loads(out)
               if c.get("workspace", {}).get("id") == ws_id
               and not c.get("floating") and c.get("mapped"))


def apply():
    global _state
    try:
        single = _tiled_count(_active_ws()) <= 1
    except Exception:
        return
    if single == _state:
        return
    _state = single
    if single:
        _hyprctl("keyword", "general:gaps_out", "0")
        _hyprctl("keyword", "general:gaps_in", "0")
        _hyprctl("keyword", "general:border_size", "0")
        _hyprctl("keyword", "decoration:rounding", "0")
    else:
        _hyprctl("keyword", "general:gaps_out", "12")
        _hyprctl("keyword", "general:gaps_in", "6")
        _hyprctl("keyword", "general:border_size", "2")
        _hyprctl("keyword", "decoration:rounding", "10")


def main():
    if not HIS:
        return
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(SOCK)
    apply()
    with s.makefile("rb") as f:
        for line in f:
            if line.split(b">>", 1)[0] in EVENTS:
                apply()


if __name__ == "__main__":
    main()
