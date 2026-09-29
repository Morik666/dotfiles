-- Hyprland 0.56 Lua configuration.
-- https://wiki.hypr.land/0.56.0/Configuring/Start/

-- Hyprspace remains disabled until it supports Hyprland 0.56.
-- hl.plugin.load("/run/current-system/sw/lib/libhyprspace.so")

require("binds")

hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@165",
    position = "0x0",
    scale = 1.6,
})
hl.monitor({
    output = "desc:Samsung Electric Company LF24T450F HK2R900537",
    mode = "1920x1080@60",
    position = "-1080x0",
    scale = 1,
    transform = 3,
})
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia --daemon")
    hl.exec_cmd("~/.config/hypr/scripts/monitor-events.sh")
    hl.exec_cmd("zen-beta", { workspace = "1 silent" })
    hl.exec_cmd("ghostty", { workspace = "2 silent" })
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

hl.config({
    input = {
        kb_layout = "us,ua",
        kb_variant = ",winkeys",
        kb_model = "",
        kb_options = "grp:win_space_toggle",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
})

-- Ignore maximize requests from applications.
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland.
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen_state_internal = 0,
        pin = false,
    },
    no_focus = true,
})

-- Keep layer-shell bars from overlapping fullscreen games.
hl.window_rule({
    name = "fullscreen-steam-games",
    match = { class = "^steam_app_[0-9]+$" },
    fullscreen = true,
})
hl.window_rule({
    name = "fullscreen-eu4",
    match = { class = "^eu4$" },
    fullscreen = true,
})

-- Fix the double cursor in Graveyard Keeper.
hl.window_rule({
    name = "confine-graveyard-keeper-pointer",
    match = { class = "^steam_app_599140$" },
    confine_pointer = true,
})
