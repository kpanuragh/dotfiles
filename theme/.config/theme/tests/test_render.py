"""Unit tests for the palette renderer."""
from pathlib import Path

import pytest

from theme import render

PALETTE = Path(__file__).resolve().parents[1] / "palettes" / "nebula-bloom.toml"


def test_load_palette_flattens_nested_tables():
    values = render.load_palette(PALETTE)
    assert values["color.base"] == "#140610"
    assert values["ansi.br_white"] == "#F6E4EE"
    assert values["geometry.rounding"] == "16"
    assert values["font.family"] == "JetBrainsMono Nerd Font"


def test_load_palette_expands_colour_variants():
    values = render.load_palette(PALETTE)
    assert values["color.magenta"] == "#FF4D9D"
    assert values["color.magenta_bare"] == "ff4d9d"
    assert values["color.magenta_rgb"] == "255, 77, 157"
    assert values["ansi.black_bare"] == "241020"


def test_render_substitutes_placeholders():
    out = render.render("bg={{ color.base }} fg={{color.text}}",
                        {"color.base": "#140610", "color.text": "#F6E4EE"})
    assert out == "bg=#140610 fg=#F6E4EE"


def test_render_leaves_unrelated_dollar_and_brace_syntax_alone():
    # hyprlock uses $var, waybar CSS uses @define-color, shell uses ${x}.
    text = "$base = rgb(x)\n@define-color a #fff;\n${SHELL}\n"
    assert render.render(text, {}) == text


def test_render_raises_on_unknown_key():
    with pytest.raises(render.UnknownKey) as exc:
        render.render("{{ color.nope }}", {"color.base": "#140610"})
    assert "color.nope" in str(exc.value)


def test_render_reports_every_unknown_key_at_once():
    with pytest.raises(render.UnknownKey) as exc:
        render.render("{{ a.x }} {{ b.y }}", {})
    assert "a.x" in str(exc.value) and "b.y" in str(exc.value)


def test_palette_has_no_duplicate_hex_for_distinct_roles():
    """base and surface0 must not collide, or window borders vanish."""
    values = render.load_palette(PALETTE)
    assert values["color.base"] != values["color.surface0"]
    assert values["color.surface1"] != values["color.surface2"]


def test_booleans_render_lowercase_not_python_repr():
    """TOML/Lua/CSS/JSON all use lowercase; str(True) == "True" is the odd one
    out and silently evaluates to nil in Lua."""
    import tomllib, tempfile, os
    with tempfile.NamedTemporaryFile("w", suffix=".toml", delete=False) as fh:
        fh.write("[geometry]\nflag_on = true\nflag_off = false\n")
        path = fh.name
    try:
        values = render.load_palette(path)
        assert values["geometry.flag_on"] == "true"
        assert values["geometry.flag_off"] == "false"
    finally:
        os.unlink(path)


def test_expands_xterm256_index_for_each_colour():
    """ranger (and other curses TUIs) take a 0-255 palette index, not a hex."""
    values = render.load_palette(PALETTE)
    # #140610 is a very dark near-black -> must land in the low cube/grey range
    assert 0 <= int(values["color.base_x256"]) <= 255
    # #FF4D9D magenta -> must be a pink/magenta cube entry, not a grey
    assert 16 <= int(values["color.magenta_x256"]) <= 231
    # exact xterm colours must map to themselves: #FFFFFF is index 231
    assert render._nearest_x256("#ffffff") == 231
    assert render._nearest_x256("#000000") == 16


def test_x256_prefers_grey_ramp_for_true_greys():
    # #808080 is closer to the grey ramp than to any cube entry
    assert 232 <= render._nearest_x256("#808080") <= 255


def test_name_snake_variant_is_a_legal_python_identifier():
    """ranger colourschemes are Python modules; "nebula-bloom" is not legal."""
    values = render.load_palette(PALETTE)
    assert values["name"] == "nebula-bloom"
    assert values["name_snake"] == "nebula_bloom"
    assert values["name_snake"].isidentifier()
