#!/bin/bash
# Catppuccin power menu via wofi
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
  *Lock*)      swaylock ;;
  *Suspend*)   systemctl suspend 2>/dev/null || loginctl suspend 2>/dev/null || sudo zzz 2>/dev/null ;;
  *Logout*)    swaymsg exit ;;
  *Reboot*)    systemctl reboot 2>/dev/null || sudo openrc-shutdown -r now ;;
  *Shutdown*)  systemctl poweroff 2>/dev/null || sudo openrc-shutdown -p now ;;
  *Hibernate*) systemctl hibernate 2>/dev/null || sudo zzz -H 2>/dev/null ;;
esac
