#!/bin/bash
# Screen magnifier via cursor:zoom_factor. arg: in | out | reset
# Bound to Mod+Ctrl+= / Mod+Ctrl+- / Mod+Ctrl+0.
set -euo pipefail
cur=$(hyprctl getoption cursor:zoom_factor -j | jq -r '.float')
new=$(awk -v c="$cur" -v a="${1:-reset}" 'BEGIN{
  if (a=="in")       n = c + 0.5;
  else if (a=="out") { n = c - 0.5; if (n < 1) n = 1 }
  else               n = 1;
  printf "%.2f", n
}')
hyprctl keyword cursor:zoom_factor "$new" >/dev/null
