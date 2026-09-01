#!/bin/bash
# Apply ~/Pictures/Wallpapers/current to all monitors via hyprpaper IPC.
# Called from Hyprland autostart and from the wallpaper switcher.
#
# Notes for hyprpaper 0.8.4:
#   - The `wallpaper =` directive in hyprpaper.conf is silently ignored (bug),
#     so we always set wallpapers via IPC.
#   - The `preload` / `unload` / `listloaded` IPC commands return "invalid
#     request"; only `wallpaper` and `listactive` work. `wallpaper` loads the
#     file on demand, so no separate preload is needed.
set -uo pipefail

# Wait for hyprpaper IPC socket (hyprpaper might be starting in parallel).
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if hyprctl hyprpaper listactive >/dev/null 2>&1; then break; fi
  sleep 0.3
done

real=$(readlink -f ~/Pictures/Wallpapers/current 2>/dev/null || true)
if [ -z "$real" ] || [ ! -f "$real" ]; then
  notify-send "Wallpaper" "~/Pictures/Wallpapers/current is missing" -u critical
  exit 1
fi

mapfile -t monitors < <(hyprctl monitors -j | python3 -c \
  'import json,sys; [print(m["name"]) for m in json.load(sys.stdin)]')

for mon in "${monitors[@]}"; do
  hyprctl hyprpaper wallpaper "$mon,$real" >/dev/null
done
