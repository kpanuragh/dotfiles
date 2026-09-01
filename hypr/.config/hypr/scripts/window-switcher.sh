#!/bin/bash
# Visual "jump to any window" switcher via wofi. Bound to Mod+W.
set -euo pipefail

list=$(hyprctl clients -j \
  | jq -r '.[] | select(.mapped==true) | "\(.address)|[\(.workspace.name)] \(.class): \(.title)"')
[ -z "$list" ] && exit 0

chosen=$(printf '%s\n' "$list" | awk -F'|' '{print $2}' \
  | wofi --dmenu -i --prompt "Window" --width 950 --height 500 --hide-scroll --no-actions) || exit 0
[ -z "$chosen" ] && exit 0

addr=$(printf '%s\n' "$list" | awk -F'|' -v c="$chosen" '$2==c {print $1; exit}')
[ -n "$addr" ] && hyprctl dispatch focuswindow "address:$addr"
