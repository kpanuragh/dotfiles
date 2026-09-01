#!/bin/bash
# Yes/No confirm before logging out of Hyprland
set -euo pipefail

choice=$(printf "%b" "  No, stay\n  Yes, log out" \
  | wofi --dmenu -i \
        --prompt "Log out?" \
        --width 320 --height 200 \
        --location center \
        --hide-scroll --no-actions || true)

case "${choice:-}" in
  *Yes*)
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      hyprctl dispatch exit
    elif [ -n "${SWAYSOCK:-}" ]; then
      swaymsg exit
    else
      loginctl terminate-session "${XDG_SESSION_ID:-self}" 2>/dev/null || pkill -KILL -u "$USER"
    fi
    ;;
esac
