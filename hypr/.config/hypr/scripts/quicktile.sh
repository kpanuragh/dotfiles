#!/bin/bash
# Snap the focused window to a half of its monitor (floats it first if tiled).
# arg: left | right | up | down. Bound to Mod+Ctrl+arrows.
# Works in logical/global coordinates and honours reserved areas (e.g. waybar).
set -euo pipefail
dir="${1:-}"

[ "$(hyprctl activewindow -j | jq -r '.floating')" != "true" ] && \
  hyprctl dispatch togglefloating >/dev/null

read -r W H X Y < <(hyprctl monitors -j | jq -r '
  .[] | select(.focused==true)
  | (.width/.scale) as $lw | (.height/.scale) as $lh
  | (.reserved[0]) as $rl | (.reserved[1]) as $rt
  | (.reserved[2]) as $rr | (.reserved[3]) as $rb
  | "\(.x) \(.y) \($lw) \($lh) \($rl) \($rt) \($rr) \($rb)"' \
  | awk -v d="$dir" '{
      mx=$1; my=$2; lw=$3; lh=$4; rl=$5; rt=$6; rr=$7; rb=$8;
      aw=lw-rl-rr; ah=lh-rt-rb; ox=mx+rl; oy=my+rt;
      hw=int(aw/2); hh=int(ah/2);
      if (d=="left")  { w=hw; h=ah; x=ox;    y=oy }
      else if (d=="right"){ w=hw; h=ah; x=ox+hw; y=oy }
      else if (d=="up")   { w=aw; h=hh; x=ox;    y=oy }
      else if (d=="down") { w=aw; h=hh; x=ox;    y=oy+hh }
      else { w=aw; h=ah; x=ox; y=oy }
      printf "%d %d %d %d\n", w, h, x, y
    }')

hyprctl --batch "dispatch resizeactive exact $W $H ; dispatch moveactive exact $X $Y" >/dev/null
