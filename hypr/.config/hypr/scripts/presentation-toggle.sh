#!/bin/bash
# Toggle "presentation mode": disable hypridle (no screen blank/lock during
# demos and calls), and re-enable it afterwards. Bound to Mod+Shift+I.
if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle
  notify-send -a Hyprland "Presentation mode ON" "Idle & auto-lock disabled" -i video-display
else
  setsid -f hypridle >/dev/null 2>&1
  notify-send -a Hyprland "Presentation mode OFF" "Idle & auto-lock restored" -i video-display
fi
