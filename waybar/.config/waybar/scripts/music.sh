#!/usr/bin/env bash
# =============================================================================
# Waybar music module (MPRIS via playerctl)
#   - Prints JSON {text,tooltip,class,alt} for the custom/music module.
#   - Maintains a resized album-art thumbnail for the image#albumart module.
# Player-agnostic: follows the active MPRIS player (Brave, mpv, Spotify,
# Gravity-Music, …) via playerctl / playerctld.
# =============================================================================
set -uo pipefail

CACHE_DIR="$HOME/.cache/waybar"
ART="$CACHE_DIR/albumart.png"      # consumed by image#albumart (same path in config)
ART_SRC="$CACHE_DIR/albumart.src"  # remembers last artUrl so we skip re-fetching
ART_SIZE=64                        # cached at 64px; image module downscales for display
mkdir -p "$CACHE_DIR"

status=$(playerctl status 2>/dev/null)

# No player running -> hide both modules and drop the cached art.
if [[ -z "$status" ]]; then
  rm -f "$ART" "$ART_SRC"
  echo '{}'
  exit 0
fi

title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)
arturl=$(playerctl metadata mpris:artUrl 2>/dev/null)
player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

# ---------------------------------------------------------------------------
# Album-art cache: fetch/convert only when the artUrl actually changes.
# ---------------------------------------------------------------------------
if [[ -n "$arturl" ]]; then
  if [[ ! -f "$ART" || "$(cat "$ART_SRC" 2>/dev/null)" != "$arturl" ]]; then
    tmp=$(mktemp); ok=0
    case "$arturl" in
      file://*)
        # percent-decode the path (e.g. %20 -> space)
        p="${arturl#file://}"; p="${p//+/ }"; p=$(printf '%b' "${p//%/\\x}")
        [[ -f "$p" ]] && cp -f "$p" "$tmp" && ok=1
        ;;
      http://*|https://*)
        curl -fsL --max-time 8 -o "$tmp" "$arturl" && ok=1
        ;;
      data:*)
        # data:image/...;base64,<payload>
        payload="${arturl#*,}"
        printf '%s' "$payload" | base64 -d > "$tmp" 2>/dev/null && ok=1
        ;;
    esac
    if [[ $ok -eq 1 ]] && magick "$tmp" -thumbnail "${ART_SIZE}x${ART_SIZE}^" \
         -gravity center -extent "${ART_SIZE}x${ART_SIZE}" "$ART" 2>/dev/null; then
      printf '%s' "$arturl" > "$ART_SRC"
    fi
    rm -f "$tmp"
  fi
else
  rm -f "$ART" "$ART_SRC"
fi

# ---------------------------------------------------------------------------
# Emit JSON (built in python3 to bulletproof escaping of titles/artists).
# ---------------------------------------------------------------------------
case "$status" in
  Playing) icon="" ; cls="playing" ;;
  Paused)  icon="" ; cls="paused"  ;;
  *)       icon="" ; cls="stopped" ;;
esac

STATUS="$status" ICON="$icon" CLS="$cls" \
TITLE="$title" ARTIST="$artist" ALBUM="$album" PLAYER="$player" \
python3 - <<'PY'
import os, json
icon   = os.environ.get("ICON", "")
cls    = os.environ.get("CLS", "")
title  = os.environ.get("TITLE", "").strip()
artist = os.environ.get("ARTIST", "").strip()
album  = os.environ.get("ALBUM", "").strip()
player = os.environ.get("PLAYER", "").strip()
status = os.environ.get("STATUS", "").strip()

if title and artist:
    body = f"{title} — {artist}"
elif title:
    body = title
else:
    body = "Unknown"

text = f"{icon}  {body}"

tip = []
if title:  tip.append(f"♪ {title}")
if artist: tip.append(f"by {artist}")
if album:  tip.append(f"on {album}")
foot = " · ".join(x for x in [player or None, status or None] if x)
if foot: tip.append("")  # blank line before footer
if foot: tip.append(foot)

print(json.dumps({
    "text": text,
    "tooltip": "\n".join(tip),
    "class": cls,
    "alt": cls,
}))
PY
