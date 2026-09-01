"""Render every template for a palette, back up what it replaces, write atomically.

Rendering happens entirely in memory first: a broken template must abort the
run before a single config file has been touched.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from theme import render

ROOT = Path(__file__).resolve().parent

# (template filename, destination relative to ~/.config)
# Later tasks append to this list; keep it ordered by tier.
#
# Destinations may contain a "{{ name }}" placeholder, resolved against the
# palette's own `name` key (see resolve_destinations) before path
# resolution, so a differently-named palette does not overwrite a file that
# still claims to be nebula-bloom.
TARGETS: list[tuple[str, str]] = [
    ("kitty-theme.conf.tmpl", "kitty/theme.conf"),
    ("btop-theme.tmpl", "btop/themes/{{ name }}.theme"),
    ("cava-config.tmpl", "cava/config"),
    ("fastfetch-config.jsonc.tmpl", "fastfetch/config.jsonc"),
    ("hypr-theme.lua.tmpl", "hypr/theme.lua"),
    ("waybar-theme.css.tmpl", "waybar/theme.css"),
    ("waybar-config.tmpl", "waybar/config"),
    ("waybar-style.css.tmpl", "waybar/style.css"),
    ("mako-config.tmpl", "mako/config"),
    ("ranger-colorscheme.py.tmpl", "ranger/colorschemes/{{ name_snake }}.py"),
    ("hyprlock.conf.tmpl", "hypr/hyprlock.conf"),
    ("vicinae-theme.toml.tmpl", "~/.local/share/vicinae/themes/{{ name }}.toml"),
    ("nvim-palette.lua.tmpl", "nvim/lua/util/palette.lua"),
    ("tmux-theme.conf.tmpl", "tmux/theme.conf"),
]

# (description, argv) — run after a successful write. Failures are reported,
# never fatal: a config is still correct if a reload hook is unavailable.
RELOADS: list[tuple[str, list[str]]] = [
    ("kitty", ["pkill", "-SIGUSR1", "kitty"]),
    ("waybar", ["pkill", "-SIGUSR2", "waybar"]),
    ("mako", ["makoctl", "reload"]),
]


def resolve_destinations(targets, values: dict[str, str]) -> list[tuple[str, str]]:
    """Substitute the palette name into TARGETS destination strings.

    Done as a separate pass, before plan() resolves paths, so a destination
    like "btop/themes/{{ name }}.theme" ends up under the applied palette's
    own name instead of a different palette silently overwriting whatever
    files nebula-bloom happened to leave behind.
    """
    return [
        (template_name, render.render(destination, values))
        for template_name, destination in targets
    ]


def plan(values: dict[str, str], targets, template_root: Path,
         dest_root: Path) -> dict[Path, str]:
    """Render every target into memory.

    Templates come from template_root. A destination beginning with "~"
    resolves against $HOME (vicinae's theme dir is outside ~/.config);
    everything else resolves against dest_root.
    """
    rendered: dict[Path, str] = {}
    for template_name, destination in targets:
        text = (template_root / template_name).read_text()
        if destination.startswith("~"):
            target = Path(destination).expanduser()
        else:
            target = dest_root / destination
        rendered[target] = render.render(text, values)
    return rendered


def backup(paths, root: Path, backup_root: Path) -> Path:
    """Snapshot every path that already exists, preserving structure.

    backup_root is passed in rather than derived from module state so the
    tests never write into the real theme/backups directory.

    Paths outside root (vicinae's theme dir) are mirrored under "external/"
    so the snapshot stays a single self-contained tree.
    """
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_dir = backup_root / stamp
    for path in paths:
        if not path.exists():
            continue
        try:
            relative = path.relative_to(root)
        except ValueError:
            relative = Path("external") / path.relative_to(path.anchor)
        destination = backup_dir / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
    backup_dir.mkdir(parents=True, exist_ok=True)
    return backup_dir


def write(rendered: dict[Path, str]) -> None:
    for path, text in rendered.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_name(path.name + ".tmp")
        temporary.write_text(text)
        os.replace(temporary, path)


def reload_apps() -> None:
    for description, argv in RELOADS:
        try:
            subprocess.run(argv, check=True, capture_output=True, timeout=10)
            print(f"  reloaded {description}")
        except (OSError, subprocess.SubprocessError) as error:
            print(f"  could not reload {description}: {error}", file=sys.stderr)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Apply a desktop theme palette.")
    parser.add_argument("palette", nargs="?", default="nebula-bloom")
    parser.add_argument("--dry-run", action="store_true",
                        help="render and report, but write nothing")
    args = parser.parse_args(argv)

    config_root = ROOT.parent
    values = render.load_palette(ROOT / "palettes" / f"{args.palette}.toml")
    targets = resolve_destinations(TARGETS, values)
    rendered = plan(values, targets, ROOT / "templates", config_root)

    if args.dry_run:
        for path in sorted(rendered):
            print(f"  would write {path}")
        return 0

    backup_dir = backup(list(rendered), config_root, ROOT / "backups")
    write(rendered)
    print(f"wrote {len(rendered)} file(s); backup in {backup_dir}")

    from theme import gtk as gtk_module

    source_theme = Path.home() / ".themes" / "catppuccin-mocha-mauve-standard+default"
    target_theme = Path.home() / ".themes" / values["name"]
    if source_theme.exists():
        mapping = {src: values[key] for src, key in gtk_module.SUBSTITUTIONS.items()}
        changed = gtk_module.build(mapping, source_theme, target_theme)
        print(f"  gtk: rewrote {len(changed)} file(s) into {target_theme}")
    else:
        print(
            f"  gtk: source theme not found at {source_theme}; "
            "GTK was NOT regenerated (leaving any previous build in place)",
            file=sys.stderr,
        )

    reload_apps()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
