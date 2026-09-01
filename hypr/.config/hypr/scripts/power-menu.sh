#!/bin/bash
# Catppuccin power menu via wofi (Hyprland)
set -euo pipefail

opts="\
  Lock\n\
  Suspend\n\
  Logout\n\
  Reboot\n\
  Shutdown\n\
󰚥  Hibernate"

choice=$(printf "%b" "$opts" | wofi --dmenu -i \
        --prompt "Power" \
        --width 280 --height 320 \
        --location center \
        --hide-scroll --no-actions || true)

case "${choice:-}" in
  *Lock*)      hyprlock ;;
  *Suspend*)   systemctl suspend 2>/dev/null || loginctl suspend 2>/dev/null ;;
  *Logout*)    hyprctl dispatch exit ;;
  *Reboot*)    systemctl reboot 2>/dev/null || sudo openrc-shutdown -r now ;;
  *Shutdown*)  systemctl poweroff 2>/dev/null || sudo openrc-shutdown -p now ;;
  *Hibernate*) systemctl hibernate 2>/dev/null ;;
esac
