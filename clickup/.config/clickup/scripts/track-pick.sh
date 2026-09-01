#!/bin/bash
# Wofi picker: choose a task, start a ClickUp timer.
set -euo pipefail

API=~/.config/clickup/scripts/clickup_api.py

# If a timer is already running, ask to stop instead of starting
running=$(python3 "$API" current 2>/dev/null || echo "")
if [ "$running" != "no timer running" ] && [ -n "$running" ]; then
  task_name=$(printf "%s" "$running" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print((d.get('task') or {}).get('name', '(unknown task)'))
")
  choice=$(printf "  Stop running timer\n  Pick a different task\n  Cancel" |
    wofi --dmenu -i --prompt "Active: $task_name" --width 380 --height 240 --location center --hide-scroll --no-actions || true)
  case "${choice:-}" in
    *Stop*)
      python3 "$API" stop >/dev/null
      rm -f ~/.cache/clickup-timer.json
      notify-send "ClickUp" "Timer stopped" -i appointment-soon
      pkill -RTMIN+8 waybar 2>/dev/null || true
      exit 0
      ;;
    *different*)
      python3 "$API" stop >/dev/null
      rm -f ~/.cache/clickup-timer.json
      ;;
    *)
      exit 0 ;;
  esac
fi

# Build wofi-friendly task list:  [status]  list  ›  task_name   <task_id>
list=$(python3 "$API" tasks 2>/dev/null) || {
  notify-send "ClickUp" "Failed to fetch tasks (check token / network)" -u critical
  exit 1
}

# Format: "STATUS  LIST › NAME ⟨id⟩"  — id is at the end, hidden-ish
formatted=$(echo "$list" | awk -F'\t' '{
  printf "  [%s] %s › %s   ⟨%s⟩\n", $2, $3, $4, $1
}' | sed 's/\[\]/[ ]/')

if [ -z "$formatted" ]; then
  notify-send "ClickUp" "No assigned tasks found" -u normal
  exit 0
fi

selected=$(printf "%s\n" "$formatted" |
  wofi --dmenu -i --prompt "Track time" --width 720 --height 540 --location center --hide-scroll --no-actions || true)

[ -z "$selected" ] && exit 0

# Extract task_id from the trailing ⟨...⟩
task_id=$(echo "$selected" | sed -nE 's/.*⟨([^⟩]+)⟩.*/\1/p')
task_name=$(echo "$selected" | sed -E 's/   ⟨[^⟩]+⟩$//' | sed -E 's/^.*› //')

if [ -z "$task_id" ]; then
  notify-send "ClickUp" "Couldn't parse task id" -u critical
  exit 1
fi

# Optional description prompt — Enter to start with whatever's typed,
# Esc / empty to start without a description.
description=$(printf "" | wofi --dmenu -i \
  --prompt "Description (optional, Enter to skip)" \
  --width 540 --height 100 --location center --hide-scroll --no-actions || true)

python3 "$API" start "$task_id" "$description" >/dev/null
rm -f ~/.cache/clickup-timer.json

if [ -n "$description" ]; then
  notify-send "ClickUp ▶ $task_name" "$description" -i appointment-new
else
  notify-send "ClickUp ▶ $task_name" "Timer started" -i appointment-new
fi

# Tell waybar to refresh the time-tracker module (signal RTMIN+8)
pkill -RTMIN+8 waybar 2>/dev/null || true
