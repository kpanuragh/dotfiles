#!/bin/bash
# Toggle gammastep (blue-light filter). gammastep is started continuously at
# login from hyprland.lua; this lets you flip it off/on manually. Bound to Mod+B.
CFG="$HOME/.config/gammastep/config.ini"
if pgrep -x gammastep >/dev/null; then
  pkill -x gammastep
  notify-send -a Hyprland "Night light OFF" -i weather-clear
else
  setsid -f gammastep -c "$CFG" >/dev/null 2>&1
  notify-send -a Hyprland "Night light ON" -i weather-clear-night
fi
