#!/bin/bash
# Screenshot helper — captures to the clipboard (and optionally to a file).
# Uses grim + slurp + wl-copy, mirroring the pattern in ocr.sh which works in
# this setup. Deliberately avoids grimblast (its internal `hyprctl` calls hang
# when spawned from a Hyprland keybind on this build).
#
#   area       region  -> clipboard
#   output     screen  -> clipboard   (all monitors)
#   window     focused -> clipboard
#   save-area  region  -> file + clipboard
set -uo pipefail

mode="${1:-area}"
save_dir="$HOME/Pictures/Screenshots"
ts="$(date +%Y-%m-%d_%H-%M-%S)"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Hyprland "Screenshot" "$1" || true; }

case "$mode" in
    area)
        geom="$(slurp 2>/dev/null)" || exit 0
        grim -g "$geom" - | wl-copy --type image/png
        notify "Region copied to clipboard"
        ;;
    output|full)
        grim - | wl-copy --type image/png
        notify "Screen copied to clipboard"
        ;;
    window)
        geom="$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" || exit 0
        grim -g "$geom" - | wl-copy --type image/png
        notify "Window copied to clipboard"
        ;;
    save-area)
        mkdir -p "$save_dir"
        geom="$(slurp 2>/dev/null)" || exit 0
        out="$save_dir/screenshot_$ts.png"
        grim -g "$geom" "$out"
        wl-copy --type image/png < "$out"
        notify "Saved $out (also copied)"
        ;;
    *)
        notify "Unknown mode: $mode"
        exit 1
        ;;
esac
