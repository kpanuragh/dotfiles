# Nebula Bloom — verified assumptions

## hyprland-lua `dofile`
- **Verdict:** PASS
- Tested: 2026-08-14. Temporary `pcall(dofile, ...)` inserted as the single
  first line of `hypr/hyprland.lua`, loading `hypr/_probe.lua`
  (`return { probe_ok = true }`). `hyprctl reload` + `hyprctl configerrors`
  reported no error; desktop kept rendering (5 mapped windows, both monitors
  intact).
- Strengthened check: extended the probe file to
  `return { probe_ok = true, bs = 3, nff = true }` and, after the pcall,
  called `hl.config({ general = { border_size = _probe.bs, no_focus_fallback
  = _probe.nff } })`. `general:no_focus_fallback` — an option never set
  anywhere else in hyprland.lua, previously reporting `set:false` — came back
  as `bool: true, set: true` after reload. This proves dofile's return table
  is genuinely consumed by `hl.config`, not silently discarded as nil.
  (`border_size` stayed at 2 because the file's later LOOK AND FEEL block
  reasserts it — expected top-to-bottom execution order, not a failure.)
- Fully reverted: probe line and `hypr/_probe.lua` removed, `hyprctl reload`
  clean, `git diff hypr/hyprland.lua` empty.

## waybar `@import`
- **Verdict:** PASS
- Tested: 2026-08-14. Added `@import "_probe.css";` as the first line of
  `waybar/style.css`, with `waybar/_probe.css` defining
  `@define-color probe_color #FF4D9D;`. Retargeted the `#custom-power` rule
  to `color: @probe_color;`. Reloaded waybar with `pkill -SIGUSR2 waybar`.
  waybar stayed alive on the same PID, both bar layers kept rendering at
  unchanged geometry, and a `grim` screenshot of the power icon showed it
  rendering bright magenta instead of its default muted red — visually
  confirming the imported color variable was consumed.
- Fully reverted: `waybar/style.css` restored from backup, `waybar/_probe.css`
  removed, waybar reloaded via SIGUSR2 (same PID, still running), a follow-up
  screenshot showed the power icon back to its default muted red, and
  `git diff --stat waybar/style.css` is empty.

## Cursors — deferred, not forgotten
Catppuccin Mocha Mauve cursors retained. Retinting needs xcursorgen /
hyprcursor-util to rebuild the binary `cursors/` set; text substitution alone
would leave XWayland cursors mauve while hyprcursor went magenta.

## Implications for later tasks
- Task 7 may create `hypr/theme.lua` and `dofile` it from the top of
  `hypr/hyprland.lua`, feeding values into `hl.config{}` in the existing
  LOOK AND FEEL block. The anchor-comment in-place-edit fallback is not
  needed.
- Task 8 may create a generated `waybar/theme.css` (or similar) and pull it
  into `waybar/style.css` via a single `@import` line near the top; the
  generator does not need to own/inline the whole `style.css` file.

## Task 14 — final verification (2026-08-14)

- **Fallback branches taken: none.** Both Task 2 verdicts above are PASS
  (hyprland-lua `dofile` and waybar `@import` both worked on the first
  probe), so the anchor-comment in-place-edit fallback described in
  "Implications for later tasks" was never needed by Task 7 or Task 8.
- **Cursors remain Catppuccin Mocha Mauve, by deliberate deferral** — see
  "Cursors — deferred, not forgotten" above. Not retinted for Nebula Bloom;
  this is a known, intentional gap, not an oversight.
- **Blur is size `8` / passes `2`, as specced** — the iGPU did not struggle,
  so the `6`-pass fallback noted in `theme/palettes/nebula-bloom.toml`
  (`blur_size = 8  # fallback if the iGPU struggles: 6`) was not taken.
  Confirmed live via `hyprctl getoption decoration:blur:size` → `8` and
  `hyprctl getoption decoration:blur:passes` → `2`.
- **Cleanup additions beyond the original Task 14 file list:** during the
  Step 3 foreign-palette sweep, two more foreign-palette leftovers were
  found and fixed (see task-14-report.md for full detail): hardcoded
  Catppuccin Mocha hex values in the waybar clock's calendar format block
  (`waybar/config`), and a stale, unreferenced `btop/themes/catppuccin_mocha.theme`
  file. Both were archived into `theme/backups/pre-nebula-abandoned-*`
  alongside the 11 `.bak*` files and the retired `kitty/hacker-matrix.conf`,
  then removed from their live locations.

## Known limitations (accepted, 2026-08-14)

Deliberate deferrals and accepted rough edges from the Nebula Bloom rollout.
None are bugs in the generated output; all were reviewed and consciously left.

- **Cursors are still Catppuccin Mocha Mauve.** See the cursors section above.
  Retinting needs xcursorgen / hyprcursor-util to rebuild the binary set.
- **tmux lost the rounded capsules.** The catppuccin plugin drew powerline
  separator glyphs; the replacement draws a flat highlight block. Window name
  and number ordering, and the active/inactive split, are reproduced. Adding
  the glyphs back is a small template change if wanted.
- **`tmux/plugins/tmux` (the catppuccin plugin) is still on disk** as a tracked
  gitlink. It is unreferenced by any active `@plugin` line and inert, but the
  fifth theme was never physically removed.
- **GTK theme thumbnails still depict Catppuccin.** `thumbnail.png` files are
  binary and copied byte-for-byte. Only visible in a theme-picker preview.
- **GTK loses one elevation step.** Catppuccin's `#181825` (mantle) and
  `#11111b` (crust) both map to `color.mantle`, so two surfaces that were
  distinguishable no longer are.
- **`gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` stay hand-maintained.**
  Their font line is not driven by the palette; every other font reference is.
- **GTK regeneration depends on the Catppuccin source theme.** `apply.py`
  recolours `~/.themes/catppuccin-mocha-mauve-standard+default`. If that
  directory is deleted, GTK is no longer regenerated — `apply` now warns
  loudly to stderr rather than skipping silently, but it cannot rebuild.
- **`cava/shaders/orion_*.frag`** — four third-party MIT shaders that appeared
  during the rollout from outside any agent's command history. Investigated,
  left untracked and untouched. Unexplained.
- Renderer edge cases, all unreachable with the current templates: nested
  `{{ {{ x }} }}` leaves stray braces rather than erroring; `UnknownKey`
  inherits `KeyError.__str__` so its message is repr-quoted when printed; the
  atomic-write temp filename is deterministic (`.tmp`) rather than unique;
  there is no `fsync` before `os.replace`; `backup()` creates an empty
  timestamped directory even when nothing was copied.

## Verification still owed by a human

- **The lock screen.** hyprlock was confirmed running healthily with the new
  config (`hyprctl locked` true WITH a live client, pid 525912), but nobody
  has visually inspected it. No agent may test it: a crashed hyprlock leaves a
  stale `ext_session_lock` that no CLI clears, recoverable only by re-login.
- **On-screen appearance of btop, cava and tmux.** Verified structurally only;
  the desktop was locked during those runs.

## Additions after the initial rollout (2026-08-14)

- **Wallpaper** set to `dotfiles-bg.jpg` (the image the palette was sampled
  from). It had never actually been applied — only used as a colour source.
- **Animations**: full Nebula Bloom set replacing Hyprland's stock defaults.
  `borderangle` is enabled but UNVERIFIED — see the comment in hyprland.lua.
- **Frosted layers**: `hl.layer_rule` blur on waybar, vicinae and mako. The
  API is `hl.layer_rule`, not `hl.layerrule` (the latter does not exist).
- **ranger is the file manager**, not dolphin. `fileManager` in hyprland.lua
  pointed at a binary that was never installed, so SUPER+SHIFT+E was a dead
  keybind. Now `kitty -e ranger`, plus a floating centred scratchpad on
  SUPER+E via the `float-ranger` window rule.
- **ranger colourscheme is generated** into `ranger/colorschemes/` from the
  palette. ranger is a curses app needing xterm-256 palette indices rather
  than hex, so `render.py` derives an `_x256` variant for every colour.
  `ranger/` was added to the repo whitelist at the same time — it had been
  untracked.
- **hyprexpo is NOT available** for Hyprland 0.55.4. The `hyprland-plugins`
  repo ships only borders-plus-plus, csgo-vulkan-fix, hyprbars and hyprfocus;
  two of those fail to build, and hyprpm reports "headers outdated" because it
  uses its own header tree rather than Gentoo's /usr/include/hyprland. No
  workspace-overview plugin is installed. The repo remains registered in
  /var/cache/hyprpm with nothing enabled — inert, and outside this repo.

## vicinae upgraded 0.21.7 -> 0.25.0 (2026-08-14)

The theme needed NO changes: v0.25.0's `theme template` lists exactly the same
15 sections as 0.21.7 ([meta], [colors.core], [colors.main_window],
[colors.settings_window], [colors.accents], [colors.shortcut], [colors.text],
[colors.text.links], [colors.input], [colors.button.primary],
[colors.list.item.hover], [colors.list.item.selection], [colors.grid.item],
[colors.scrollbars], [colors.loading]) — verified by diffing the new binary's
own template output against the generated file, not by trusting the changelog.

Install is still an AppImage at ~/Applications, symlinked from
~/.local/bin/vicinae. Rollback: repoint that symlink at
Vicinae-x86_64.AppImage.bak-v0.21.7 and restart the server.

Note: the original reason for using an AppImage has lapsed — it was that
system Qt was 6.10.3 while vicinae needed 6.11. System Qt is now 6.11.1. There
is still no vicinae ebuild in ::guru or ::hyproverlay, so the AppImage remains
the practical route, but the blocker itself is gone.

Gotcha for future work: `pkill -f "vicinae server"` KILLS THE CALLING SHELL,
because -f matches the full command line and the shell's own line contains
that string. Kill vicinae by PID (pgrep -x vicinae-server) instead.
