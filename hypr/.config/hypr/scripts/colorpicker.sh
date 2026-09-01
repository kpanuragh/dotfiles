#!/bin/bash
# Pick a pixel color, copy hex to clipboard, notify
set -euo pipefail

hex=$(hyprpicker -a -f hex -n 2>/dev/null || true)
if [ -z "${hex:-}" ]; then
  notify-send "Color picker" "No color picked"
  exit 0
fi

printf "%s" "$hex" | wl-copy
notify-send "Color picker" "$hex copied to clipboard" -i color-picker
