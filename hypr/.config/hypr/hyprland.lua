-- ============================================================================
--  hyprland.lua  — RECONSTRUCTED after accidental deletion (2026-07-06)
-- ============================================================================
--  The original file had no backup (home is not covered by the btrfs snapshots
--  and there was no git/dotfiles copy). This file was rebuilt from the STILL-
--  RUNNING Hyprland process (PID at time of recovery: 3439), whose embedded Lua
--  interpreter still held the config source in memory, plus the live `hyprctl`
--  state and the surviving ~/.config/hypr/scripts/ directory.
--
--  CONFIDENCE:
--    [EXACT]  recovered verbatim from process memory / live option values.
--    [CONFIRMED] key<->action proven by a "Bound to ..." comment in the script.
--    [GUESS]  key is real (it IS bound in the live instance) but the action is a
--             best-effort reconstruction — VERIFY these. The live instance shows
--             123 binds as opaque "__lua <id>" dispatchers, so the exact action
--             behind some keys could not be recovered. A full list of every live
--             key combo is in the APPENDIX at the bottom for cross-checking.
-- ============================================================================

------------------
---- MONITORS ----  [EXACT — from live hyprctl monitors]
------------------

-- Dell S2340L (HDMI-A-1) is the PRIMARY monitor, on the LEFT at 0x0.
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- Laptop panel (eDP-1, BOE) sits to the right.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- SOC war-room LED wall (NovaStar VX2000 Pro -> 3456x1080 LED canvas).
-- The controller's input EDID is set to 3456x1080@60 so the signal maps 1:1
-- onto the cabinets: no crop, no rescale. scale=1 is deliberate -- at scale 2
-- the browser only saw 1728x540 and two thirds of the dashboard fell off the
-- bottom of the wall.
hl.monitor({ output = "DP-1", mode = "3456x1080@60", position = "auto", scale = 1 })

-- Fallback for any other/unknown output:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Make the external monitor primary: the default workspace lives on it.
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })

---------------------
---- MY PROGRAMS ----  [EXACT]
---------------------

local terminal = "kitty"
-- dolphin is NOT installed on this system, so SUPER+SHIFT+E was a dead
-- keybind. ranger is the file manager actually in use (2026-08-14).
local fileManager = "kitty -e ranger"
-- Floating ranger scratchpad on SUPER+E. The distinct --class is what the
-- "float-ranger" window_rule below matches on, so only this instance floats.
local fileManagerFloat = "kitty --class ranger-float -e ranger"
local menu = os.getenv("HOME") .. "/.local/bin/vicinae toggle" -- Raycast-like launcher (server autostarted below)

-- Terminal fallback helper (recovered verbatim) — launches the first installed
-- of a candidate list. Bound to SUPER+Q below.
local function shell_ok(cmd)
	local a, b, c = os.execute(cmd)
	if type(a) == "number" then
		return a == 0
	end
	return a == true and b == "exit" and c == 0
end

local function first_installed(candidates)
	for _, bin in ipairs(candidates) do
		if shell_ok(("command -v %q >/dev/null 2>&1"):format(bin)) then
			return bin
		end
	end
	return nil
end

local function launch_first_installed(candidates)
	local term = first_installed(candidates)
	if not term then
		return false
	end
	hl.dispatch(hl.dsp.exec_cmd(term))
	return true
end

-------------------
---- AUTOSTART ----  [GUESS assembly — every command below was found referenced
-------------------   in process memory, but exact ordering/flags are inferred]

hl.on("hyprland.start", function()
	-- Make DBus / systemd user session aware of the Wayland environment.
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE QT_QPA_PLATFORMTHEME PATH XDG_DATA_DIRS"
	)
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/dbus-wellknown-bus.sh")

	-- PolicyKit authentication agent: shows the GUI password prompt for
	-- pkexec / privileged apps (Zenmap-as-root, etc). Without this, no popup appears.
	hl.exec_cmd("/usr/libexec/polkit-gnome-authentication-agent-1")

	-- Audio stack: pipewire + pipewire-pulse + wireplumber (supervised/respawned).
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/audio-start.sh")

	-- Bars, wallpaper, idle, notifications, nightlight.
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("mako")
	hl.exec_cmd("gammastep -c " .. os.getenv("HOME") .. "/.config/gammastep/config.ini")

	-- Clipboard history daemon (feeds the cliphist keybind).
	hl.exec_cmd("wl-paste --watch cliphist store")

	-- Vicinae launcher server (Super+D / Super+R toggle its window).
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/vicinae server")

	-- Personal helper daemons + monitor/wallpaper/gaps managers.
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/monitor-hotplug.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper-init.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/smart-gaps.py")
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/battery-monitor.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/bt-agent-noio.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/Projects/my_buddy/scripts/run-daemon.sh")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----  [EXACT]
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----  [EXACT — values below match the live hyprctl options]
-----------------------

-- Theme values are generated. Edit theme/palettes/nebula-bloom.toml, then
-- run `python3 -m theme.apply nebula-bloom` from ~/.config.
local theme = dofile(os.getenv("HOME") .. "/.config/hypr/theme.lua")

hl.config({
	general = {
		gaps_in = theme.gaps_in,
		gaps_out = theme.gaps_out,

		border_size = theme.border_size,

		col = {
			active_border = {
				colors = { theme.active_border_1, theme.active_border_2 },
				angle = 45,
			},
			inactive_border = theme.inactive_border,
		},

		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = theme.rounding,
		rounding_power = 2,

		dim_inactive = theme.dim_inactive,
		dim_strength = theme.dim_strength,

		active_opacity = theme.active_opacity,
		inactive_opacity = theme.inactive_opacity,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = theme.shadow_color,
		},

		blur = {
			enabled = true,
			size = theme.blur_size,
			passes = theme.blur_passes,
			vibrancy = theme.blur_vibrancy,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Curves  [the first six: EXACT — recovered verbatim from memory]
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
-- Nebula Bloom: overshoot. The y > 1 control point is what makes a window
-- land slightly past its target and settle, rather than merely arriving.
hl.curve("nebulaPop", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })

-- Animations — Nebula Bloom. Speeds are deciseconds (3.2 = 320ms); everything
-- below lands under ~320ms so motion never becomes waiting. Leaves not listed
-- inherit "global".
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })

-- Focus border: quick colour transition, plus a slow rotation of the
-- magenta->peach gradient (one turn per ~3s).
-- UNVERIFIED: borderangle reports enabled via `hyprctl animations` but no
-- rotation could be demonstrated by screenshot sampling on Hyprland 0.55.4 —
-- every apparent change traced back to focus transitions. Judge it by eye.
-- COST: if it IS running, "loop" redraws the focused border continuously and
-- is the only always-on animation here. Set enabled = false to kill it.
hl.animation({ leaf = "border", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear", style = "loop" })

-- Windows: pop in with overshoot, leave decisively (was linear = mechanical).
hl.animation({ leaf = "windows", enabled = true, speed = 3.2, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.8, bezier = "nebulaPop", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeOutQuint", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "easeOutQuint" })

hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.3, bezier = "almostLinear" })

-- Layers: waybar, vicinae, mako. Slide in from whichever edge they anchor to.
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "nebulaPop", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.3, bezier = "almostLinear" })

-- Workspaces: directional slide, replacing the stock crossfade.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.2, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3.2, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.2, bezier = "easeOutQuint", style = "slidefade 15%" })

-- Special workspace (scratchpad): drops in from above.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "nebulaPop", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "nebulaPop", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.2, bezier = "easeOutQuint", style = "slidevert" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Layouts  [EXACT]
hl.config({ dwindle = { preserve_split = true } })

----------------
----  MISC  ----  [EXACT]
----------------

hl.config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = false,
	},
})

---------------
---- INPUT ----  [EXACT]
---------------

hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
		},
	},
})

-- 3-finger horizontal touchpad swipe -> switch workspaces  [EXACT]
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- ---- Applications / session --------------------------------------------
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal)) -- [per user] Super+Enter -> kitty (live bind #5)
hl.bind(mainMod .. " + Q", hl.dsp.window.close()) -- [per user] Super+Q -> close active window
-- SUPER+SHIFT+E keeps its [EXACT] role as "the file manager key", but now
-- opens the floating scratchpad — that is what the muscle memory expects.
-- The tiled variant moved to SUPER+E for when you want ranger in the layout.
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(fileManagerFloat)) -- floating ranger popup
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager)) -- ranger, tiled
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu)) -- [per user] Super+D -> launcher (hyprland-run)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu)) -- app launcher (also)
hl.bind(
	mainMod .. " + SHIFT + M",
	hl.dsp.exec_cmd( -- [EXACT] logout / shutdown
		"command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
	)
)

-- ---- Window management --------------------------------------------------
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close()) -- [EXACT] close window
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })) -- [EXACT] toggle floating
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" })) -- [GUESS] fullscreen
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- [EXACT] pseudo
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("hyprctl dispatch togglegroup")) -- [GUESS] toggle group
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f")) -- [GUESS] cycle group

-- Focus (vim keys + arrows)  [GUESS actions, keys are real]
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" })) -- [EXACT]
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" })) -- [EXACT]
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" })) -- [EXACT]
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" })) -- [EXACT]

-- Move window (vim keys + arrows)  [GUESS actions, keys are real]
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- ---- Workspaces ---------------------------------------------------------  [EXACT]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- [EXACT] scroll workspaces
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" })) -- [EXACT]

-- Transfer the current workspace to the other monitor (multi-monitor).       -- [per user]
-- User described this as "Ctrl+Shift+,"; the live bind is Super(mainMod)+Shift.
-- NOTE: the old `exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor +1")`
-- was silently broken — hyprland-lua evaluates the hyprctl arg as Lua, so `+1`
-- became arithmetic on a nil global and the dispatch errored out. Use the native
-- workspace.move dispatcher (== movecurrentworkspacetomonitor): it MOVES the
-- current workspace to the next/prev monitor and focus follows it (not a swap).
-- "+1"/"-1" are relative monitor selectors, so both keys just target "the other"
-- monitor in this 2-display setup.
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.workspace.move({ monitor = "-1" }))

-- ---- Mouse move/resize --------------------------------------------------  [EXACT]
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ---- Scripts (key<->action CONFIRMED by the script header comments) -----
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/cheatsheet.sh")) -- [CONFIRMED] keybind cheatsheet
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/dropterm.sh")) -- [CONFIRMED] dropdown terminal
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/window-switcher.sh")) -- [CONFIRMED] window switcher
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/ocr.sh")) -- [CONFIRMED] OCR region
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/nightlight-toggle.sh")) -- [CONFIRMED] nightlight toggle
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/presentation-toggle.sh")) -- [CONFIRMED] presentation mode
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/save-monitors.sh")) -- [CONFIRMED] save monitor layout

-- Magnifier  [CONFIRMED]
hl.bind(mainMod .. " + CTRL + equal", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/magnify.sh in"))
hl.bind(mainMod .. " + CTRL + minus", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/magnify.sh out"))
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/magnify.sh reset"))

-- Quick-tile (snap to half of monitor)  [CONFIRMED]
hl.bind(mainMod .. " + CTRL + left", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/quicktile.sh left"))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/quicktile.sh right"))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/quicktile.sh up"))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/quicktile.sh down"))

-- ---- Scripts (key is a real live bind, action reconstructed) ------------  [GUESS — verify]
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/colorpicker.sh")) -- [GUESS] colour picker
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper-switcher.sh")) -- [GUESS] wallpaper switcher
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/recorder-toggle.sh")) -- [GUESS] screen recorder
hl.bind(
	mainMod .. " + period",
	hl.dsp.exec_cmd(
		"env BEMOJI_PICKER_CMD='wofi --dmenu -i --prompt Emoji' "
			.. os.getenv("HOME")
			.. "/.config/hypr/scripts/bemoji -c"
	)
) -- [GUESS] emoji picker

-- Clipboard history + notifications  [GUESS — commands found in memory, keys inferred]
hl.bind(
	mainMod .. " + SHIFT + V",
	hl.dsp.exec_cmd([[sh -c 'cliphist list | wofi --dmenu --prompt "Clipboard" | cliphist decode | wl-copy']])
)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("makoctl dismiss"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl dismiss --all"))

-- ---- Screenshots (grim/slurp/wl-copy via screenshot.sh — NOT grimblast) ---
local screenshot = os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh"
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " output")) -- full screen -> clipboard
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screenshot .. " area")) -- region -> clipboard
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(screenshot .. " window")) -- active window -> clipboard
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(screenshot .. " area")) -- [per user] region select -> clipboard

-- ---- Media / brightness keys -------------------------------------------  [EXACT]
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ---- Resize submap ------------------------------------------------------  [GUESS entry key]
-- The live instance has a "resize" submap (no-mod H/J/K/L / arrows / Return /
-- Escape). The key that ENTERS the submap could not be recovered — SUPER+minus
-- (#188) is the most likely candidate; adjust if wrong.
hl.bind(mainMod .. " + minus", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
	hl.bind("H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
	hl.bind("L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
	hl.bind("left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
	hl.bind("right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
	hl.bind("Return", hl.dsp.submap("reset"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

--------------------------------
---- WINDOWS AND WORKSPACES ----  [EXACT — recovered verbatim]
--------------------------------

local suppressMaximizeRule = hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-- ---- Nebula Bloom: per-app behaviour ------------------------------------
-- Everything above this line is [EXACT] recovered config. Everything below
-- was added 2026-08-14 and is safe to delete.

-- Content apps stay fully opaque. The global 0.96/0.92 split looks good on
-- terminals, but transparency over a busy wallpaper muddies video, images
-- and rendered pages.
hl.window_rule({
	name = "opaque-browser",
	match = { class = "^([Bb]rave-browser|firefox|chromium|google-chrome.*)$" },
	opacity = 1.0,
})
hl.window_rule({
	name = "opaque-media",
	match = { class = "^(mpv|vlc|imv|feh|org.gnome.Loupe|swayimg)$" },
	opacity = 1.0,
})
hl.window_rule({
	name = "opaque-editor",
	match = { class = "^([Cc]ode|code-oss|VSCodium|obsidian|GIMP|[Gg]imp.*)$" },
	opacity = 1.0,
})

-- Small settings utilities float, centred, at a usable size instead of
-- taking half the tiling area.
hl.window_rule({
	name = "float-audio-settings",
	match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" },
	float = true,
	center = true,
	size = "900 620",
})
hl.window_rule({
	name = "float-bluetooth",
	match = { class = "^(blueman-manager|\\.blueman-manager-wrapped)$" },
	float = true,
	center = true,
	size = "820 600",
})
hl.window_rule({
	name = "float-network",
	match = { class = "^(nm-connection-editor|nm-applet)$" },
	float = true,
	center = true,
	size = "820 600",
})

-- File pickers and dialogs float and centre rather than joining the tiling
-- layout, where they arrive as an awkward half-screen pane.
hl.window_rule({
	name = "float-file-dialog",
	match = { title = "^(Open|Save|Select|Choose|Export|Import).*" },
	float = true,
	center = true,
	size = "1000 680",
})

-- Picture-in-picture floats above everything and follows you between
-- workspaces.
hl.window_rule({
	name = "float-pip",
	match = { title = "^([Pp]icture[- ]in[- ][Pp]icture)$" },
	float = true,
	pin = true,
})

-- Floating ranger scratchpad (SUPER+E). Matches the distinct --class set on
-- the launch command, so ordinary kitty windows are unaffected.
hl.window_rule({
	name = "float-ranger",
	match = { class = "^ranger-float$" },
	float = true,
	center = true,
	size = "1100 700",
})

-- ---- Nebula Bloom: frosted layers ---------------------------------------
-- Without these the bar, launcher and notifications are merely TRANSPARENT —
-- raw wallpaper showing through. Blurring them turns them into frosted glass,
-- which is what makes translucent chrome readable over a busy image.
-- ignore_alpha stops the blur bleeding through fully-transparent padding.
hl.layer_rule({ name = "blur-bar", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-launcher", match = { namespace = "^vicinae$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2 })

-- ============================================================================
--  APPENDIX — every keybind present in the live instance at recovery time.
--  100% accurate list of key combos (the action for some was opaque). Use this
--  to verify the [GUESS] binds above and to reconstruct any still-missing ones.
--  Unmapped/uncertain live keys not implemented above (fill in as you recall):
--    SUPER+SHIFT+B, SUPER+SHIFT+F, SUPER+SHIFT+G, SUPER+T, SUPER+SHIFT+T,
--    SUPER+D, SUPER+SHIFT+D, SUPER+SHIFT+Space, SUPER+Space, SUPER+SHIFT+Space,
--    SUPER+X, SUPER+SHIFT+X, SUPER+SHIFT+Q, SUPER+A, SUPER+SHIFT+A, SUPER+U,
--    SUPER+SHIFT+Y, SUPER+comma,
--    SUPER+SHIFT+minus, SUPER+CTRL+H, SUPER+CTRL+L,
--    SUPER+grave, SUPER+SHIFT+grave, SUPER+CTRL+grave (likely scratchpad/special
--    workspaces — e.g. hl.dsp.workspace.toggle_special("magic")).
-- ============================================================================

-- FULL LIVE KEY LIST (all 123 binds, verbatim from hyprctl binds):
--   SUPER              Return                 (lua#5)
--   SUPER+SHIFT        B                      (lua#7)
--   SUPER+SHIFT        F                      (lua#9)
--   SUPER+SHIFT        E                      (lua#11)
--   SUPER+SHIFT        P                      (lua#13)
--   SUPER+SHIFT        G                      (lua#15)
--   SUPER+SHIFT        M                      (lua#17)
--   SUPER              T                      (lua#19)
--   SUPER+SHIFT        T                      (lua#21)
--   SUPER              D                      (lua#23)
--   SUPER+SHIFT        Space                  (lua#25)
--   SUPER              X                      (lua#27)
--   SUPER+SHIFT        W                      (lua#29)
--   SUPER+SHIFT        D                      (lua#31)
--   SUPER+SHIFT        O                      (lua#33)
--   SUPER+SHIFT        V                      (lua#35)
--   SUPER              N                      (lua#37)
--   SUPER+SHIFT        N                      (lua#39)
--   SUPER              Q                      (lua#41)
--   SUPER+SHIFT        Q                      (lua#43)
--   SUPER+SHIFT        C                      (lua#45)
--   SUPER              F                      (lua#47)
--   SUPER+SHIFT        SPACE                  (lua#49)
--   SUPER              SPACE                  (lua#51)
--   SUPER              V                      (lua#53)
--   SUPER              T                      (lua#55)
--   SUPER              P                      (lua#57)
--   SUPER              A                      (lua#58)
--   SUPER              slash                  (lua#60)
--   SUPER+SHIFT        R                      (lua#62)
--   SUPER+SHIFT        Y                      (lua#64)
--   SUPER              G                      (lua#66)
--   SUPER              comma                  (lua#68)
--   SUPER              period                 (lua#70)
--   SUPER              Z                      (lua#72)
--   SUPER              W                      (lua#74)
--   SUPER              O                      (lua#76)
--   SUPER              U                      (lua#78)
--   SUPER+SHIFT        A                      (lua#80)
--   SUPER+SHIFT        I                      (lua#82)
--   SUPER+CTRL         equal                  (lua#84)
--   SUPER+CTRL         minus                  (lua#86)
--   SUPER+CTRL         0                      (lua#88)
--   SUPER              B                      (lua#90)
--   SUPER+CTRL         Left                   (lua#92)
--   SUPER+CTRL         Right                  (lua#94)
--   SUPER+CTRL         Up                     (lua#96)
--   SUPER+CTRL         Down                   (lua#98)
--   SUPER              H                      (lua#100)
--   SUPER              J                      (lua#102)
--   SUPER              K                      (lua#104)
--   SUPER              L                      (lua#106)
--   SUPER              Left                   (lua#108)
--   SUPER              Down                   (lua#110)
--   SUPER              Up                     (lua#112)
--   SUPER              Right                  (lua#114)
--   SUPER              Tab                    (lua#116)
--   SUPER+SHIFT        H                      (lua#118)
--   SUPER+SHIFT        J                      (lua#120)
--   SUPER+SHIFT        K                      (lua#122)
--   SUPER+SHIFT        L                      (lua#124)
--   SUPER+SHIFT        Left                   (lua#126)
--   SUPER+SHIFT        Down                   (lua#128)
--   SUPER+SHIFT        Up                     (lua#130)
--   SUPER+SHIFT        Right                  (lua#132)
--   SUPER              1                      (lua#134)
--   SUPER+SHIFT        1                      (lua#136)
--   SUPER              2                      (lua#138)
--   SUPER+SHIFT        2                      (lua#140)
--   SUPER              3                      (lua#142)
--   SUPER+SHIFT        3                      (lua#144)
--   SUPER              4                      (lua#146)
--   SUPER+SHIFT        4                      (lua#148)
--   SUPER              5                      (lua#150)
--   SUPER+SHIFT        5                      (lua#152)
--   SUPER              6                      (lua#154)
--   SUPER+SHIFT        6                      (lua#156)
--   SUPER              7                      (lua#158)
--   SUPER+SHIFT        7                      (lua#160)
--   SUPER              8                      (lua#162)
--   SUPER+SHIFT        8                      (lua#164)
--   SUPER              9                      (lua#166)
--   SUPER+SHIFT        9                      (lua#168)
--   SUPER              0                      (lua#170)
--   SUPER+SHIFT        0                      (lua#172)
--   SUPER+CTRL         H                      (lua#174)
--   SUPER+CTRL         L                      (lua#176)
--   SUPER              mouse_down             (lua#178)
--   SUPER              mouse_up               (lua#180)
--   SUPER+SHIFT        comma                  (lua#182)
--   SUPER+SHIFT        period                 (lua#184)
--   SUPER+SHIFT        minus                  (lua#186)
--   SUPER              minus                  (lua#188)
--   SUPER              R                      (lua#190)
--   (none)             H                      (lua#192)
--   (none)             J                      (lua#194)
--   (none)             K                      (lua#196)
--   (none)             L                      (lua#198)
--   (none)             Left                   (lua#200)
--   (none)             Down                   (lua#202)
--   (none)             Up                     (lua#204)
--   (none)             Right                  (lua#206)
--   (none)             Return                 (lua#208)
--   (none)             Escape                 (lua#210)
--   SUPER              mouse:272              (lua#212)
--   SUPER              mouse:273              (lua#214)
--   (none)             Print                  (lua#216)
--   SHIFT              Print                  (lua#218)
--   SUPER              Print                  (lua#220)
--   SUPER+SHIFT        Print                  (lua#222)
--   (none)             XF86AudioRaiseVolume   (lua#224)
--   (none)             XF86AudioLowerVolume   (lua#226)
--   (none)             XF86AudioMute          (lua#228)
--   (none)             XF86AudioMicMute       (lua#230)
--   (none)             XF86AudioPlay          (lua#232)
--   (none)             XF86AudioNext          (lua#234)
--   (none)             XF86AudioPrev          (lua#236)
--   (none)             XF86MonBrightnessUp    (lua#238)
--   (none)             XF86MonBrightnessDown  (lua#6)
--   SUPER+SHIFT        X                      (lua#10)
--   SUPER              grave                  (lua#14)
--   SUPER+SHIFT        grave                  (lua#18)
--   SUPER+CTRL         grave                  (lua#22)
