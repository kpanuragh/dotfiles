#!/usr/bin/env bash
# Persist the current live Hyprland monitor layout (e.g. arranged via wdisplays)
# into the WDISPLAYS-MANAGED block of hyprland.lua. Bound to Mod+Shift+O.
set -euo pipefail

CONF="${HOME}/.config/hypr/hyprland.lua"
BEGIN='-- >>> WDISPLAYS-MANAGED'
END='-- <<< WDISPLAYS-MANAGED'

command -v hyprctl >/dev/null || { echo "hyprctl not found"; exit 1; }
command -v jq >/dev/null || { echo "jq not found"; exit 1; }
[ -f "$CONF" ] || { echo "config not found: $CONF"; exit 1; }
grep -qFe "$BEGIN" "$CONF" || { echo "begin marker missing in $CONF"; exit 1; }
grep -qFe "$END"   "$CONF" || { echo "end marker missing in $CONF"; exit 1; }

# Generate one hl.monitor{} block per enabled monitor from the live layout.
genfile="$(mktemp)"
trap 'rm -f "$genfile"' EXIT
hyprctl monitors -j | jq -r '
  map(select(.disabled == false)) | .[] |
  "hl.monitor({\n" +
  "    output   = \"\(.name)\",\n" +
  "    mode     = \"\(.width)x\(.height)@\(.refreshRate | (.*100|round)/100)\",\n" +
  "    position = \"\(.x)x\(.y)\",\n" +
  "    scale    = \"\(.scale | (.*100|round)/100)\",\n" +
  "})"
' > "$genfile"

[ -s "$genfile" ] || { echo "no enabled monitors reported; config untouched"; exit 1; }

# Splice: replace everything between the markers with the generated block.
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" -v gf="$genfile" '
  index($0, b) { print; while ((getline line < gf) > 0) print line; close(gf); skip=1; next }
  index($0, e) { skip=0 }
  !skip { print }
' "$CONF" > "$tmp"

# Sanity-check before overwriting.
if ! grep -qFe "$BEGIN" "$tmp" || ! grep -qFe "$END" "$tmp" || [ ! -s "$tmp" ]; then
  echo "splice failed; config left untouched"; rm -f "$tmp"; exit 1
fi

cp "$CONF" "${CONF}.bak-$(date +%Y%m%d-%H%M%S)"
mv "$tmp" "$CONF"
notify-send -a Hyprland "Displays" "Monitor layout saved to hyprland.lua" 2>/dev/null \
  || echo "Monitor layout saved to hyprland.lua"
