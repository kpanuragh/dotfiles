#!/bin/bash
# Quake-style dropdown terminal on a dedicated special workspace (special:dropterm).
# Bound to Mod+Z. First press spawns kitty (class "dropterm"); subsequent presses
# toggle it in/out. A window_rule in hyprland.lua floats + sizes it.
set -euo pipefail

if hyprctl clients -j | jq -e '.[] | select(.class=="dropterm")' >/dev/null 2>&1; then
  hyprctl dispatch togglespecialworkspace dropterm
else
  hyprctl dispatch exec '[workspace special:dropterm silent] kitty --class dropterm'
  for _ in $(seq 1 30); do
    hyprctl clients -j | jq -e '.[] | select(.class=="dropterm")' >/dev/null 2>&1 && break
    sleep 0.05
  done
  hyprctl dispatch togglespecialworkspace dropterm
fi
