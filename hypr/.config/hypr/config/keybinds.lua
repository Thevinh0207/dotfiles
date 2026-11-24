local p = dofile("/home/vinh/.config/hypr/config/programs.lua")
local mainMod = p.mainMod

-- Locking screen keybind
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- See https://wiki.hypr.land/configuring/core/binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(p.terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(
	mainMod .. " + SHIFT + DELETE",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(p.fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(p.menu))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + U", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Windows manipulation and window switching
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/alt-tab.sh next"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/alt-tab.sh prev"))
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

-- Workspace manipulation keybinds
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + BACKSPACE", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + N", hl.dsp.focus({ workspace = "empty" }))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "empty" }))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/close-workspace.sh"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/close-workspace-force.sh"))

-- Waybar reset keybind
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("touch /tmp/waybar-peek"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/restart-bar.sh"))

-- Power mode keybind
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/power-mode.sh"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/battery-limit.sh"))

-- Wallpaper change keybind
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/next-wallpaper.sh"))

-- Study mode keybind
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("~/.config/hypr/scripts/study-mode.sh"))

-- nightLight keybind
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Quick menu pop up
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call panel toggle"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio and brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh volume-up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh volume-down"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh brightness-up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh brightness-down"),
	{ locked = true, repeating = true }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
