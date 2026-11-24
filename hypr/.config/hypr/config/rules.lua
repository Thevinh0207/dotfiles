-- See https://wiki.hypr.land/configuring/core/rules/

-- Noti for volume and brightness
hl.layer_rule({
	name = "notification-blur",
	match = { namespace = "notifications" },
	blur = true,
	ignore_alpha = 0.2,
})

-- WayBar sliding animation
hl.layer_rule({
	name = "waybar-slide",
	match = { namespace = "waybar" },
	animation = "slide top",
})

-- Quick menu window rule
hl.window_rule({
	name = "quick-menu-float",
	match = {
		class = "^(nmtui|blueman-manager|\\.blueman-manager-wrapped|pavucontrol|org\\.pulseaudio\\.pavucontrol)$",
	},

	float = true,
	center = true,
	size = "900 600",
})

hl.window_rule({
	-- Ignore maximize requests from all apps
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
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

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Workspace function
for i = 1, 2 do
	hl.workspace_rule({ workspace = tostring(i), persistent = true })
end
