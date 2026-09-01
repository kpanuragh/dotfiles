#!/bin/bash
# Wallpaper switcher for Hyprland (uses hyprpaper IPC).
# Picks an image with wofi, applies it to every connected monitor,
# updates the ~/Pictures/Wallpapers/current symlink for persistence.
set -euo pipefail

dir="$HOME/Pictures/Wallpapers"
cd "$dir"

mapfile -t files < <(find . -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
  -not -name 'current' -printf '%f\n' | sort)

[ ${#files[@]} -eq 0 ] && { notify-send "Wallpapers" "No images in $dir"; exit 1; }

choice=$(printf '%s\n' "${files[@]}" | wofi --dmenu -i \
        --prompt "Wallpaper" \
        --width 520 --height 420 \
        --location center \
        --hide-scroll || true)

[ -z "${choice:-}" ] && exit 0
[ ! -f "$dir/$choice" ] && { notify-send "Wallpaper" "Not found: $choice"; exit 1; }

# Persist symlink, then apply via IPC.
# hyprpaper 0.8.4 only honours `wallpaper`/`listactive` over IPC; preload/unload
# return "invalid request". `wallpaper` loads on demand, so no preload needed.
ln -sfn "$choice" "$dir/current"
real="$(readlink -f "$dir/$choice")"

mapfile -t monitors < <(hyprctl monitors -j | python3 -c 'import json,sys; [print(m["name"]) for m in json.load(sys.stdin)]')
for mon in "${monitors[@]}"; do
  hyprctl hyprpaper wallpaper "$mon,$real" >/dev/null
done

notify-send "Wallpaper" "$choice" -i "$real"
