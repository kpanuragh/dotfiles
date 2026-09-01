#!/bin/bash
# Show keybindings in wofi, parsed from the Lua source (hyprland.lua). Bound to Mod+/.
# The live `hyprctl binds` only exposes opaque "__lua <id>" dispatchers, so we read
# the source for human-readable actions. Replaces the old hyprland.conf parser.
set -euo pipefail
LUA="$HOME/.config/hypr/hyprland.lua"

python3 - "$LUA" <<'PY' | wofi --dmenu -i --prompt "Keybindings" \
       --width 980 --height 750 --location center --hide-scroll --no-actions >/dev/null || true
import re, sys

lua = open(sys.argv[1]).read()
lines = lua.splitlines()

# Resolve simple `local name = "value"` definitions (mod, term, browser, ...).
vars = {}
for l in lines:
    m = re.match(r'\s*local\s+(\w+)\s*=\s*"([^"]*)"', l)
    if m:
        vars[m.group(1)] = m.group(2)
MOD = vars.get("mod", "SUPER")

def resolve_key(expr):
    out = []
    for p in expr.split(".."):
        p = p.strip()
        if len(p) >= 2 and p[0] == '"' and p[-1] == '"':
            out.append(p[1:-1])
        elif p == "mod":
            out.append(MOD)
        elif p in vars:
            out.append(vars[p])
        else:
            return None  # placeholder like fd[1]/key/i -> skip, summarised below
    return "".join(out).strip()

def simplify(a):
    a = a.strip().rstrip("),").strip()
    m = re.search(r'exec_cmd\(\s*"([^"]*)"', a)
    if m: return m.group(1)
    m = re.search(r'exec_cmd\(\s*\[\[(.*?)\]\]', a, re.S)
    if m: return re.sub(r'\s+', ' ', m.group(1)).strip()[:90]
    m = re.search(r'exec_cmd\(\s*(\w+)', a)
    if m: return vars.get(m.group(1), m.group(1))
    m = re.search(r'hl\.dsp\.([\w.]+)', a)
    if m: return m.group(1).replace(".", " ")
    if "function" in a: return "(action)"
    return a[:90]

section = "General"
out = []
for l in lines:
    ms = re.match(r'\s*--\s*[─\-]{2,}\s*(.+?)\s*[─\-]*$', l)
    if ms:
        t = ms.group(1)
        section = t.split(":")[-1].strip() if ":" in t else t.strip()
        continue
    mb = re.match(r'\s*hl\.bind\(\s*(.+)$', l)
    if not mb:
        continue
    rest = mb.group(1)
    if "," not in rest:
        continue
    keyexpr, action = rest.split(",", 1)   # keys here never contain commas
    key = resolve_key(keyexpr)
    if not key:
        continue
    out.append(f"{key:<22}  {simplify(action):<40}  [{section}]")

# Loop-generated binds aren't literal hl.bind lines — summarise them.
extra = [
    (f"{MOD} + H/J/K/L / arrows", "focus left/down/up/right", "Focus"),
    (f"{MOD} + SHIFT + H/J/K/L",  "move window in direction", "Move"),
    (f"{MOD} + 1..0",             "switch to workspace 1-10", "Workspaces"),
    (f"{MOD} + SHIFT + 1..0",     "move window to workspace", "Workspaces"),
]
for k, a, s in extra:
    out.append(f"{k:<22}  {a:<40}  [{s}]")

print("\n".join(out))
PY
