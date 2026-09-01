"""Generate a GTK 3/4 theme by recolouring an existing text-based theme.

The Catppuccin theme is CSS plus SVG assets with no binaries, so retinting is
a substitution over both #rrggbb and rgba(r, g, b, a) forms.
"""

from __future__ import annotations

import re
import shutil
from collections import Counter
from pathlib import Path

TEXT_SUFFIXES = {".css", ".svg"}

# Catppuccin Mocha Mauve source colour -> Nebula Bloom palette key.
#
# The base 16 below cover the colours documented as dominant in the source
# theme. Auditing the actual installed theme
# (~/.themes/catppuccin-mocha-mauve-standard+default) turned up two more
# genuine Catppuccin accent colours used in gtk-4.0's CSS (peach and blue,
# 14 occurrences each, used for warning/info states) that are not part of
# that dominant set — they are included here so the completeness check
# (find_unmapped) comes back empty.
SUBSTITUTIONS = {
    "#1e1e2e": "color.base",       # base
    "#181825": "color.mantle",     # mantle
    "#11111b": "color.mantle",     # crust
    "#313244": "color.surface0",   # surface0
    "#45475a": "color.surface1",   # surface1
    "#585b70": "color.surface2",   # surface2
    "#cba6f7": "color.magenta",    # mauve accent
    "#bf9de9": "color.magenta",    # accent, hover shade
    "#f38ba8": "color.red",        # red
    "#bb6d85": "color.red",        # red, darker shade
    "#f9e2af": "color.yellow",     # yellow
    "#a6e3a1": "color.green",      # green
    "#89dceb": "color.cyan",       # sky
    "#eff1f5": "color.text",       # text
    "#393947": "color.surface1",
    "#282938": "color.surface0",
    "#fab387": "color.peach",      # peach accent (gtk-4.0 warning states)
    "#89b4fa": "color.blue",       # blue accent (gtk-4.0 info states)
    # The entries below have no literal #hex form anywhere in the source —
    # they only ever appear as rgba(r, g, b, a) decimal triplets (tooltip
    # backgrounds, cinnamon workspace-switcher overlays). substitute() only
    # needs a hex string to derive r,g,b for the rgba regex, so a hex key is
    # still the vehicle even though it never matches literally. Found by
    # exhaustively enumerating every rgba(...) triple in the source tree.
    "#0b0b12": "color.mantle",     # rgba(11, 11, 18) — near-black tooltip bg
    "#9d81c0": "color.violet",     # rgba(157, 129, 192) — muted violet overlay
    "#1b1b2b": "color.mantle",     # rgba(27, 27, 43) — cinnamon overlay
    "#2f2f4a": "color.surface1",   # rgba(47, 47, 74) — cinnamon overlay
    "#050508": "color.mantle",     # rgba(5, 5, 8) — cinnamon overlay
    "#38385a": "color.surface1",   # rgba(56, 56, 90) — cinnamon overlay
}


def _hex_to_rgb(value: str) -> tuple[int, int, int]:
    bare = value.lstrip("#")
    return tuple(int(bare[i:i + 2], 16) for i in (0, 2, 4))


# Matches either a bare #rrggbb token or the numeric prefix of an rgba(...)
# call. A single combined pattern lets substitute() do the whole replacement
# in ONE re.sub pass (see FINDING 7): re.sub scans the input left-to-right
# exactly once and never re-examines text it has already emitted, so one
# mapping entry's target can never be repainted by another entry's source
# even if the two happen to collide (e.g. mapping A's target equals mapping
# B's source).
_TOKEN = re.compile(
    r"(?P<hex>#[0-9A-Fa-f]{6})"
    r"|rgba\(\s*(?P<r>\d+)\s*,\s*(?P<g>\d+)\s*,\s*(?P<b>\d+)\s*,\s*"
)


def substitute(text: str, mapping: dict[str, str]) -> str:
    """Replace every source colour, in both #hex and rgba() form, in one pass."""
    hex_lookup = {source.lower(): target for source, target in mapping.items()}
    rgb_lookup = {
        _hex_to_rgb(source): _hex_to_rgb(target) for source, target in mapping.items()
    }

    def _replace(match: re.Match[str]) -> str:
        hex_token = match.group("hex")
        if hex_token is not None:
            target = hex_lookup.get(hex_token.lower())
            return target if target is not None else match.group(0)
        rgb = (int(match.group("r")), int(match.group("g")), int(match.group("b")))
        target_rgb = rgb_lookup.get(rgb)
        if target_rgb is None:
            return match.group(0)
        tr, tg, tb = target_rgb
        return f"rgba({tr}, {tg}, {tb}, "

    return _TOKEN.sub(_replace, text)


# Identity fields inside a GTK metatheme's index.theme that must name the
# generated theme rather than whatever the source Catppuccin package shipped.
# Handled explicitly (not via TEXT_SUFFIXES/substitute) because these are
# name fields, not colours — see FINDING 6.
_INDEX_THEME_ICON_THEME = "Papirus-Dark"
_INDEX_THEME_LINE = re.compile(r"^([A-Za-z]+)=(.*)$", re.MULTILINE)


def rewrite_index_theme(text: str, name: str) -> str:
    """Rewrite an index.theme's identity fields to name the generated theme.

    GtkTheme/MetacityTheme are set to `name` so they match the on-disk
    theme directory name (what desktop theme choosers resolve against).
    IconTheme is pinned to the icon theme actually configured elsewhere
    (Papirus-Dark), not the source theme's own icon pairing.
    """
    replacements = {
        "Name": name,
        "Comment": f"{name} — generated by theme/apply.py",
        "GtkTheme": name,
        "MetacityTheme": name,
        "IconTheme": _INDEX_THEME_ICON_THEME,
    }

    def _replace(match: re.Match[str]) -> str:
        key = match.group(1)
        if key in replacements:
            return f"{key}={replacements[key]}"
        return match.group(0)

    return _INDEX_THEME_LINE.sub(_replace, text)


def _rewrite_tree(root: Path, mapping: dict[str, str], name: str) -> list[str]:
    """Apply colour substitution and index.theme identity rewrites under root."""
    rewritten: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        if path.name == "index.theme":
            original = path.read_text(encoding="utf-8", errors="strict")
            updated = rewrite_index_theme(original, name)
            if updated != original:
                path.write_text(updated, encoding="utf-8")
                rewritten.append(str(path.relative_to(root)))
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        original = path.read_text(encoding="utf-8", errors="strict")
        updated = substitute(original, mapping)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            rewritten.append(str(path.relative_to(root)))
    return rewritten


def build(mapping: dict[str, str], source: Path, destination: Path) -> list[str]:
    """Build the recoloured theme atomically.

    The whole build happens in a sibling temp directory first; destination
    is only ever touched by the final rename, and only after every file has
    been copied and rewritten successfully (see FINDING 4). A failure at any
    point during the copy/rewrite leaves the pre-existing destination, if
    any, completely untouched.
    """
    temp_destination = destination.with_name(destination.name + ".tmp-build")
    if temp_destination.exists():
        shutil.rmtree(temp_destination)

    shutil.copytree(source, temp_destination, symlinks=True)
    rewritten = _rewrite_tree(temp_destination, mapping, destination.name)

    stale_backup = destination.with_name(destination.name + ".tmp-old")
    if stale_backup.exists():
        shutil.rmtree(stale_backup)

    previous = None
    if destination.exists():
        destination.rename(stale_backup)
        previous = stale_backup

    try:
        temp_destination.rename(destination)
    except OSError:
        if previous is not None:
            previous.rename(destination)
        raise

    if previous is not None:
        shutil.rmtree(previous)

    return rewritten


def find_unmapped(destination: Path, sources: list[str]) -> dict[str, int]:
    """Count any source colours that survived — a non-empty result is a bug."""
    counts: Counter[str] = Counter()
    for path in destination.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        for source in sources:
            hits = text.count(source.lower())
            if hits:
                counts[source] += hits
    return dict(counts)
