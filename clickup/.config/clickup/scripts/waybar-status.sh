#!/bin/bash
# Output JSON for the waybar custom/clickup module.
#
# Strategy:
# - Tick locally every 1 second; recompute elapsed from cached `start`.
# - Refresh from ClickUp every CACHE_TTL seconds.
# - If a refresh FAILS (transient network/API error), keep showing the
#   last-known timer instead of falling back to "idle". This is what
#   used to make the bar drop to idle every minute or two.
# - Only return idle when ClickUp itself says no timer is running.
set -euo pipefail
exec 2>>"$HOME/.cache/clickup-waybar.log"

python3 - <<'PY'
import json, os, sys, time, importlib.util, urllib.error, urllib.request
from pathlib import Path

CACHE_FILE = Path.home() / ".cache" / "clickup-timer.json"
CACHE_TTL  = 25       # seconds between API refreshes
STALE_OK   = 5 * 60   # if API down, keep showing cached state up to 5 min

CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)

# Load shared API module without spawning subprocesses
spec = importlib.util.spec_from_file_location(
    "ck", os.path.expanduser("~/.config/clickup/scripts/clickup_api.py")
)
ck = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ck)

ICON_CLOCK = chr(0xF017)
ICON_PLAY  = chr(0xF04B)
ICON_WARN  = chr(0xF071)
TRIANGLE   = chr(0x25B6)


def fetch_current():
    """Direct API call — does NOT call sys.exit on failure (unlike ck.current_timer)."""
    cfg = ck.load_config()
    url = f"{ck.API}/team/{cfg['team_id']}/time_entries/current"
    req = urllib.request.Request(url, headers={"Authorization": ck.load_token()})
    with urllib.request.urlopen(req, timeout=10) as r:
        resp = json.loads(r.read())
    data = resp.get("data") or {}
    if not data or data.get("end") not in (None, "0", 0, ""):
        return None
    return data


def load_cache():
    if not CACHE_FILE.exists():
        return None, None
    try:
        payload = json.loads(CACHE_FILE.read_text())
        return payload.get("timer"), payload.get("fetched_at", 0)
    except Exception:
        return None, None


def save_cache(timer):
    CACHE_FILE.write_text(json.dumps({"timer": timer, "fetched_at": time.time()}))


timer, fetched_at = load_cache()
age = time.time() - fetched_at if fetched_at else float("inf")

stale = age >= CACHE_TTL
network_failed = False

if stale:
    try:
        timer = fetch_current()
        save_cache(timer)
    except Exception as e:
        network_failed = True
        sys.stderr.write(f"[{time.strftime('%F %T')}] fetch failed: {e!r}\n")
        # Don't overwrite cache — keep showing the last known state.

# Render
if timer is None:
    if network_failed and age <= STALE_OK:
        # Transient error, but cache says no timer was running last we saw.
        # Show a soft warning so we know we're not getting fresh data.
        print(json.dumps({
            "text":    f"{ICON_WARN} {ICON_CLOCK} idle",
            "tooltip": f"ClickUp: API unreachable, last fetch {int(age)}s ago",
            "class":   "error",
        }))
    else:
        print(json.dumps({
            "text":    f"{ICON_CLOCK} idle",
            "tooltip": "ClickUp: no timer running\nMod+T to start",
            "class":   "idle",
        }))
    sys.exit(0)

# Timer running — compute elapsed from start time
start_ms  = int(timer.get("start") or 0)
elapsed_s = max(0, int(time.time()) - start_ms // 1000)
h, s = divmod(elapsed_s, 3600)
m, s = divmod(s, 60)
elapsed = f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"

task   = timer.get("task") or {}
name   = task.get("name", "(unknown)")
status = (task.get("status") or {}).get("status", "")
desc   = (timer.get("description") or "").strip()
short  = name if len(name) <= 28 else name[:27] + "…"

tooltip_lines = [f"ClickUp {TRIANGLE}  {name}", f"[{status}]"]
if desc:
    tooltip_lines.append(f"✎ {desc}")
tooltip_lines += [f"elapsed {elapsed}", "click to stop"]
if network_failed:
    tooltip_lines.append(f"(API stale by {int(age)}s)")

print(json.dumps({
    "text":    f"{ICON_PLAY} {short}  {elapsed}",
    "tooltip": "\n".join(tooltip_lines),
    "class":   "running",
    "alt":     elapsed,
}))
PY
