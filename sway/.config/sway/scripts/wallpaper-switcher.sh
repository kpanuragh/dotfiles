#!/bin/bash
# Wallpaper switcher — wofi list of files in ~/Pictures/Wallpapers/
# Updates the 'current' symlink and reloads sway's bg.
set -euo pipefail

dir="$HOME/Pictures/Wallpapers"
cd "$dir"

# Build a name list (skip the symlink itself)
mapfile -t files < <(find . -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\n' | sort)

[ ${#files[@]} -eq 0 ] && { notify-send "Wallpapers" "No images in $dir"; exit 1; }

choice=$(printf '%s\n' "${files[@]}" | wofi --dmenu -i \
        --prompt "Wallpaper" \
        --width 520 --height 420 \
        --location center \
        --hide-scroll || true)

[ -z "${choice:-}" ] && exit 0
[ ! -f "$dir/$choice" ] && { notify-send "Wallpaper" "Not found: $choice"; exit 1; }

ln -sfn "$choice" "$dir/current"

# Tell sway to re-apply the bg without a full reload
swaymsg "output * bg $dir/current fill #1e1e2e" >/dev/null
notify-send "Wallpaper" "Set to $choice"
