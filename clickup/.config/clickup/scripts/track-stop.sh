#!/bin/bash
# Stop the running ClickUp timer (used by waybar click).
set -euo pipefail
API=~/.config/clickup/scripts/clickup_api.py
out=$(python3 "$API" stop 2>&1) || {
  notify-send "ClickUp" "$out" -u critical
  exit 1
}
rm -f ~/.cache/clickup-timer.json
notify-send "ClickUp ⏹" "Timer stopped" -i appointment-soon
pkill -RTMIN+8 waybar 2>/dev/null || true
