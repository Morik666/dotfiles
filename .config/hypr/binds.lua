local mainMod = "SUPER"
local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "noctalia msg panel-toggle launcher"
local controlCenter = "noctalia msg panel-toggle control-center"
local sessionMenu = "noctalia msg panel-toggle session"
local clipboard = "noctalia msg panel-toggle clipboard"
local reloadShell = "sh -c 'if pgrep -x .noctalia-wrapp >/dev/null; then noctalia msg config-reload; else noctalia --daemon; fi'"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(sessionMenu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(clipboard))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
-- SUPER + Tab remains disabled until Hyprspace supports Hyprland 0.56.
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(reloadShell))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(controlCenter))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor-layout.sh rotate-external"))
hl.bind("Print", hl.dsp.exec_cmd("flameshot gui"))

-- Move focus, or move the current workspace to another monitor.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))

-- Switch workspaces, or move the active window and follow it.
for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows by dragging with the mouse.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness keys repeat and remain available while locked.
local mediaKeys = {
    { "XF86AudioRaiseVolume", "volume-up" },
    { "XF86AudioLowerVolume", "volume-down" },
    { "XF86AudioMute", "volume-mute" },
    { "XF86AudioMicMute", "mic-mute" },
    { "XF86MonBrightnessUp", "brightness-up" },
    { "XF86MonBrightnessDown", "brightness-down" },
}
for _, binding in ipairs(mediaKeys) do
    hl.bind(binding[1], hl.dsp.exec_cmd("noctalia msg " .. binding[2]), { locked = true, repeating = true })
end

-- Keep workspace placement predictable when the laptop lid changes state.
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor-layout.sh lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor-layout.sh lid-open"), { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
