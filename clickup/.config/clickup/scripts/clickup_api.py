#!/usr/bin/env python3
"""ClickUp time-tracker — shared API helpers.

Token: ~/.config/clickup/token (mode 600)
Config: ~/.config/clickup/config.json (team_id, user_id)
"""
from __future__ import annotations
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

CFG_DIR = Path.home() / ".config" / "clickup"
TOKEN_FILE = CFG_DIR / "token"
CONFIG_FILE = CFG_DIR / "config.json"
CACHE_FILE = CFG_DIR / "tasks-cache.json"
CACHE_TTL = 300  # 5 min

API = "https://api.clickup.com/api/v2"


def load_token() -> str:
    return TOKEN_FILE.read_text().strip()


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_FILE.read_text())


def request(method: str, path: str, *, params: dict | None = None, body: dict | None = None) -> Any:
    url = API + path
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url,
        method=method,
        data=data,
        headers={
            "Authorization": load_token(),
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"ClickUp API {method} {path} -> {e.code}: {e.read().decode(errors='replace')}\n")
        sys.exit(1)


def my_open_tasks(*, refresh: bool = False) -> list[dict]:
    """Tasks assigned to the current user, open status, across the team."""
    if not refresh and CACHE_FILE.exists():
        age = time.time() - CACHE_FILE.stat().st_mtime
        if age < CACHE_TTL:
            return json.loads(CACHE_FILE.read_text())

    cfg = load_config()
    tasks: list[dict] = []
    page = 0
    while True:
        resp = request(
            "GET",
            f"/team/{cfg['team_id']}/task",
            params={
                "assignees[]": cfg["user_id"],
                "include_closed": "false",
                "subtasks": "true",
                "order_by": "updated",
                "reverse": "true",
                "page": page,
            },
        )
        batch = resp.get("tasks", [])
        tasks.extend(batch)
        if len(batch) < 100 or page > 5:  # cap at 600 tasks
            break
        page += 1

    PICKER_STATUSES = {"backlog", "to do", "in progress"}

    # Slim down to fields we use, filter to actionable statuses, persist
    slim = [
        {
            "id": t["id"],
            "name": t["name"],
            "status": status,
            "list":   (t.get("list")   or {}).get("name",   ""),
            "folder": (t.get("folder") or {}).get("name",   ""),
            "url":    t.get("url", ""),
        }
        for t in tasks
        for status in [((t.get("status") or {}).get("status", "")).lower()]
        if status in PICKER_STATUSES
    ]
    CACHE_FILE.write_text(json.dumps(slim))
    return slim


def current_timer() -> dict | None:
    cfg = load_config()
    resp = request("GET", f"/team/{cfg['team_id']}/time_entries/current")
    data = resp.get("data") or {}
    if not data or data.get("end") not in (None, "0", 0, ""):
        return None
    return data


def start_timer(task_id: str, description: str = "") -> dict:
    cfg = load_config()
    body: dict[str, Any] = {"tid": task_id}
    if description:
        body["description"] = description
    return request("POST", f"/team/{cfg['team_id']}/time_entries/start", body=body)


def stop_timer() -> dict:
    cfg = load_config()
    return request("POST", f"/team/{cfg['team_id']}/time_entries/stop")


def fmt_duration_ms(ms: int | str) -> str:
    s = int(ms) // 1000
    h, s = divmod(s, 3600)
    m, s = divmod(s, 60)
    return f"{h:d}:{m:02d}:{s:02d}" if h else f"{m:d}:{s:02d}"


if __name__ == "__main__":
    # Tiny CLI for manual ops
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "tasks":
        for t in my_open_tasks(refresh="--refresh" in sys.argv):
            print(f"{t['id']}\t[{t['status']}]\t{t['list']}\t{t['name']}")
    elif cmd == "current":
        c = current_timer()
        print(json.dumps(c, indent=2) if c else "no timer running")
    elif cmd == "start":
        desc = sys.argv[3] if len(sys.argv) > 3 else ""
        print(json.dumps(start_timer(sys.argv[2], desc), indent=2))
    elif cmd == "stop":
        print(json.dumps(stop_timer(), indent=2))
    else:
        print("usage: clickup_api.py {tasks|current|start <task_id>|stop} [--refresh]")
        sys.exit(2)
