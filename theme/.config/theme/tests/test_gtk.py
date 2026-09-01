"""Unit tests for GTK theme generation."""
import pytest

from theme import gtk


def test_substitutes_hex_case_insensitively():
    out = gtk.substitute("color: #1E1E2E; border: #1e1e2e;",
                         {"#1e1e2e": "#140610"})
    assert out == "color: #140610; border: #140610;"


def test_substitutes_rgba_triplets():
    """Catppuccin writes the same colours as rgba(30, 30, 46, 0.5)."""
    out = gtk.substitute("rgba(30, 30, 46, 0.5)", {"#1e1e2e": "#140610"})
    assert out == "rgba(20, 6, 16, 0.5)"


def test_substitutes_rgba_without_spaces():
    out = gtk.substitute("rgba(30,30,46,0.5)", {"#1e1e2e": "#140610"})
    assert out == "rgba(20, 6, 16, 0.5)"


def test_leaves_unrelated_colours_alone():
    out = gtk.substitute("#abcdef rgba(1, 2, 3, 1)", {"#1e1e2e": "#140610"})
    assert out == "#abcdef rgba(1, 2, 3, 1)"


def test_build_copies_and_rewrites_css_and_svg(tmp_path):
    source = tmp_path / "src"
    (source / "gtk-3.0" / "assets").mkdir(parents=True)
    (source / "gtk-3.0" / "gtk.css").write_text("a { color: #1e1e2e; }")
    (source / "gtk-3.0" / "assets" / "check.svg").write_text('<svg fill="#cba6f7"/>')
    (source / "gtk-3.0" / "thumbnail.png").write_bytes(b"\x89PNG binary")

    destination = tmp_path / "out"
    gtk.build({"#1e1e2e": "#140610", "#cba6f7": "#FF4D9D"}, source, destination)

    assert (destination / "gtk-3.0" / "gtk.css").read_text() == "a { color: #140610; }"
    assert (destination / "gtk-3.0" / "assets" / "check.svg").read_text() == '<svg fill="#FF4D9D"/>'
    # binaries are copied byte-for-byte, never text-substituted
    assert (destination / "gtk-3.0" / "thumbnail.png").read_bytes() == b"\x89PNG binary"


def test_build_reports_surviving_source_colours(tmp_path):
    source = tmp_path / "src"
    source.mkdir()
    (source / "gtk.css").write_text("a { color: #1e1e2e; } b { color: #313244; }")
    destination = tmp_path / "out"
    gtk.build({"#1e1e2e": "#140610"}, source, destination)
    assert gtk.find_unmapped(destination, ["#313244"]) == {"#313244": 1}


def test_substitute_is_single_pass_not_cascading():
    """A later pass must not repaint an earlier pass's output.

    Falsifiability: an iterative implementation (one re.sub per mapping
    entry, applied to the whole text in sequence) would, with this mapping,
    first turn the original #aaaaaa region into #bbbbbb and then, on the
    very next entry's #bbbbbb -> #cccccc pass, repaint that SAME
    already-substituted region to #cccccc too -- losing the #aaaaaa mapping
    outcome entirely. A correct single-pass implementation looks up each
    token's ORIGINAL colour exactly once, so the two regions end up with
    their correct, distinct final colours.
    """
    mapping = {"#aaaaaa": "#bbbbbb", "#bbbbbb": "#cccccc"}
    out = gtk.substitute("one=#aaaaaa two=#bbbbbb", mapping)
    assert out == "one=#bbbbbb two=#cccccc"


def test_build_is_atomic_on_failure(tmp_path, monkeypatch):
    """A failure during the build must leave a pre-existing destination intact.

    Falsifiability: the old implementation did `rmtree(destination)` then
    `copytree(source, destination)` directly, so a failure partway through
    the copy would leave `destination` gone or partially written. This test
    forces `shutil.copytree` to blow up and asserts the pre-existing
    destination — including its original content — survives untouched.
    """
    source = tmp_path / "src"
    source.mkdir()
    (source / "gtk.css").write_text("a { color: #1e1e2e; }")

    destination = tmp_path / "out"
    destination.mkdir()
    (destination / "sentinel.css").write_text("previous build, still good")

    def _boom(*args, **kwargs):
        raise OSError("simulated disk failure mid-copy")

    monkeypatch.setattr(gtk.shutil, "copytree", _boom)

    with pytest.raises(OSError):
        gtk.build({"#1e1e2e": "#140610"}, source, destination)

    assert destination.exists()
    assert (destination / "sentinel.css").read_text() == "previous build, still good"


def test_build_rewrites_index_theme_identity_fields(tmp_path):
    source = tmp_path / "src"
    source.mkdir()
    (source / "index.theme").write_text(
        "[Desktop Entry]\n"
        "Type=X-GNOME-Metatheme\n"
        "Name=catppuccin-mocha-mauve-standard+default\n"
        "Comment=An Flat Gtk+ theme based on Elegant Design\n"
        "Encoding=UTF-8\n"
        "\n"
        "[X-GNOME-Metatheme]\n"
        "GtkTheme=catppuccin-mocha-mauve-standard+default\n"
        "MetacityTheme=catppuccin-mocha-mauve-standard+default\n"
        "IconTheme=Tela-circle-Dark\n"
        "CursorTheme=Mocha-cursors\n"
        "ButtonLayout=close,minimize,maximize:menu\n"
    )
    destination = tmp_path / "nebula-bloom"
    gtk.build({}, source, destination)
    text = (destination / "index.theme").read_text()

    assert "catppuccin" not in text.lower()
    assert "Name=nebula-bloom" in text
    assert "GtkTheme=nebula-bloom" in text
    assert "MetacityTheme=nebula-bloom" in text
    assert "IconTheme=Papirus-Dark" in text
    # Untouched fields survive as-is.
    assert "CursorTheme=Mocha-cursors" in text
    assert "ButtonLayout=close,minimize,maximize:menu" in text
