"""Unit tests for the apply orchestrator."""
from pathlib import Path

import pytest

from theme import apply


def _palette():
    return {"color.base": "#140610", "color.text": "#F6E4EE"}


def _templates(tmp_path, **files):
    """Create a template directory and return (template_root, dest_root)."""
    template_root = tmp_path / "templates"
    template_root.mkdir(exist_ok=True)
    for name, text in files.items():
        (template_root / name.replace("__", ".")).write_text(text)
    return template_root, tmp_path / "dest"


def test_plan_renders_all_targets_to_memory(tmp_path):
    template_root, dest_root = _templates(tmp_path, a__tmpl="bg={{ color.base }}")
    out = apply.plan(_palette(), [("a.tmpl", "sub/a.conf")], template_root, dest_root)
    assert out == {dest_root / "sub" / "a.conf": "bg=#140610"}


def test_plan_raises_before_writing_anything(tmp_path):
    """A bad template must abort the whole run with nothing on disk."""
    template_root, dest_root = _templates(
        tmp_path,
        good__tmpl="{{ color.base }}",
        bad__tmpl="{{ color.nope }}",
    )
    with pytest.raises(apply.render.UnknownKey):
        apply.plan(_palette(),
                   [("good.tmpl", "g.conf"), ("bad.tmpl", "b.conf")],
                   template_root, dest_root)
    assert not (dest_root / "g.conf").exists()
    assert not (dest_root / "b.conf").exists()


def test_plan_resolves_home_relative_destinations(tmp_path, monkeypatch):
    """vicinae's theme dir lives outside ~/.config."""
    monkeypatch.setenv("HOME", str(tmp_path / "home"))
    template_root, dest_root = _templates(tmp_path, t__tmpl="{{ color.base }}")
    out = apply.plan(_palette(), [("t.tmpl", "~/themes/x.json")],
                     template_root, dest_root)
    assert list(out)[0] == tmp_path / "home" / "themes" / "x.json"


def test_resolve_destinations_substitutes_palette_name():
    """A destination like 'btop/themes/{{ name }}.theme' must resolve against
    whichever palette is actually being applied, not stay hardcoded to
    nebula-bloom (FINDING 5): otherwise `apply other-palette` overwrites
    nebula-bloom's own theme file with content claiming to be nebula-bloom.
    """
    targets = [("btop-theme.tmpl", "btop/themes/{{ name }}.theme"),
               ("kitty-theme.conf.tmpl", "kitty/theme.conf")]
    out = apply.resolve_destinations(targets, {"name": "other-palette", "name_snake": "other-palette".replace("-", "_")})
    assert out == [("btop-theme.tmpl", "btop/themes/other-palette.theme"),
                    ("kitty-theme.conf.tmpl", "kitty/theme.conf")]


def test_backup_snapshots_only_existing_files(tmp_path):
    existing = tmp_path / "here.conf"
    existing.write_text("old contents")
    missing = tmp_path / "nested" / "absent.conf"
    backup_dir = apply.backup([existing, missing], tmp_path, tmp_path / "bk")
    assert (backup_dir / "here.conf").read_text() == "old contents"
    assert not (backup_dir / "nested" / "absent.conf").exists()


def test_backup_preserves_directory_structure(tmp_path):
    nested = tmp_path / "waybar" / "style.css"
    nested.parent.mkdir()
    nested.write_text("css")
    backup_dir = apply.backup([nested], tmp_path, tmp_path / "bk")
    assert (backup_dir / "waybar" / "style.css").read_text() == "css"


def test_backup_mirrors_paths_outside_root_under_external(tmp_path):
    """vicinae's theme file lives outside ~/.config."""
    outside = tmp_path / "elsewhere" / "theme.json"
    outside.parent.mkdir()
    outside.write_text("{}")
    root = tmp_path / "config"
    root.mkdir()
    backup_dir = apply.backup([outside], root, tmp_path / "bk")
    mirrored = list(backup_dir.rglob("theme.json"))
    assert len(mirrored) == 1
    assert "external" in mirrored[0].parts


def test_write_creates_parent_directories(tmp_path):
    target = tmp_path / "deep" / "nest" / "file.conf"
    apply.write({target: "content"})
    assert target.read_text() == "content"


def test_write_is_atomic_leaving_no_temp_files(tmp_path):
    target = tmp_path / "file.conf"
    apply.write({target: "content"})
    assert [p.name for p in tmp_path.iterdir()] == ["file.conf"]


def test_write_replaces_existing_content(tmp_path):
    target = tmp_path / "file.conf"
    target.write_text("stale")
    apply.write({target: "fresh"})
    assert target.read_text() == "fresh"


def test_write_failure_leaves_original_file_intact(tmp_path, monkeypatch):
    """A failure during the write step must not corrupt the existing file.

    Falsifiability: a non-atomic implementation that writes straight to the
    destination (e.g. `path.write_text(text)`, no temp file, no replace)
    would already have overwritten `target` by the time any failure could
    occur, so this test would fail against it. Simulating the failure via
    `os.replace` (the atomic rename step) proves the write went to a
    temporary file first and only swaps it in on success.
    """
    target = tmp_path / "file.conf"
    target.write_text("original contents")

    def _boom(*args, **kwargs):
        raise OSError("simulated replace failure")

    monkeypatch.setattr(apply.os, "replace", _boom)

    with pytest.raises(OSError):
        apply.write({target: "new contents"})

    assert target.read_text() == "original contents"
