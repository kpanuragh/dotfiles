#!/bin/bash
# OCR: select a screen region, extract text with tesseract, copy to clipboard.
# Bound to Mod+O.
set -euo pipefail
command -v tesseract >/dev/null || { notify-send -a Hyprland "OCR" "tesseract not installed"; exit 1; }

tmp=$(mktemp --suffix=.png)
base="${tmp%.png}"
trap 'rm -f "$tmp" "$base.txt"' EXIT

region=$(slurp 2>/dev/null) || exit 0
[ -z "$region" ] && exit 0
grim -g "$region" "$tmp"

tesseract "$tmp" "$base" -l eng >/dev/null 2>&1
txt=$(cat "$base.txt" 2>/dev/null || true)

if [ -n "$(printf '%s' "$txt" | tr -d '[:space:]')" ]; then
  printf '%s' "$txt" | wl-copy
  notify-send -a Hyprland "OCR" "Copied $(printf '%s' "$txt" | wc -w) words to clipboard"
else
  notify-send -a Hyprland "OCR" "No text detected"
fi
