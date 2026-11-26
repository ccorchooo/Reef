-- This config's keys. Reef's own keys (search on a Super tap, Island, Coral, control
-- center, overview, Alt+Tab, lock, power, media and brightness keys, Print) are in
-- reef.lua and aren't repeated here; nothing below takes one of them.
--
--   SUPER + Return / T        terminal            SUPER + 1…0          go to workspace
--   SUPER + W                 browser             SUPER + SHIFT + 1…0  move window there (and follow)
--   SUPER + SHIFT + E         files               SUPER + ALT + 1…0    move window there (stay)
--   SUPER + SHIFT + T         editor              SUPER + CTRL + ←/→   previous / next workspace
--   SUPER + Q                 close window        SUPER + scroll        previous / next workspace
--   SUPER + SHIFT + Q         kill window         SUPER + S            scratchpad
--   SUPER + F / M             fullscreen / maximize  SUPER + ALT + S    window to scratchpad
--   SUPER + SHIFT + F         float               SUPER + ALT + M / D  music / chat workspace
--   SUPER + P                 pin                 SUPER + R            resize mode (arrows, Esc)
--   SUPER + arrows            focus               SUPER + J            swap split (dwindle)
--   SUPER + SHIFT + arrows    move window         SUPER + backslash    next layout
--   SUPER + ALT + arrows      resize              SUPER + G            group / ungroup
--   SUPER + mouse L / R       move / resize       SUPER + [ / ]        previous / next in group
--   SUPER + SHIFT + S         screenshot          SUPER + SHIFT + .    color picker
--   SUPER + CTRL + R          restart Reef        SUPER + comma        focus other monitor
local vars = require("reef.vars")
local lib  = require("reef.lib")
local mod  = vars.mod
local apps = vars.apps

local function k(keys) return mod .. " + " .. keys end
local repeating = { repeating = true }
local locked    = { locked = true }

---------------------------------------------------------------- apps

lib.bind({ k("Return"), k("T") }, hl.dsp.exec_cmd(apps.terminal))
lib.bind(k("W"), hl.dsp.exec_cmd(apps.browser))
lib.bind(k("SHIFT + E"), hl.dsp.exec_cmd(apps.files))
if apps.editor then lib.bind(k("SHIFT + T"), hl.dsp.exec_cmd(apps.editor)) end
if apps.picker then lib.bind(k("SHIFT + period"), hl.dsp.exec_cmd(apps.picker)) end
-- A region screenshot through Reef (Print does the same).
lib.bind(k("SHIFT + S"), hl.dsp.global("reef:screenshot"), locked)
-- Restart the shell (after an update, or if it misbehaves).
lib.bind(k("CTRL + R"), hl.dsp.exec_cmd("qs kill -c reef; qs -c reef -n -d"))

---------------------------------------------------------------- windows

lib.bind(k("Q"), hl.dsp.window.close())
lib.bind(k("SHIFT + Q"), hl.dsp.window.kill())
lib.bind(k("F"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
lib.bind(k("M"), hl.dsp.window.fullscreen({ mode = "maximized" }))
lib.bind(k("SHIFT + F"), function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    local w = hl.get_active_window()
    if w and w.floating then hl.dispatch(hl.dsp.window.center()) end
end)
lib.bind(k("P"), hl.dsp.window.pin())
lib.bind(k("J"), hl.dsp.layout("togglesplit"))

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    lib.bind(k(dir), hl.dsp.focus({ direction = dir }))
    lib.bind(k("SHIFT + " .. dir), hl.dsp.window.move({ direction = dir }))
end
local step = 40
lib.bind(k("ALT + left"),  hl.dsp.window.resize({ x = -step, y = 0, relative = true }), repeating)
lib.bind(k("ALT + right"), hl.dsp.window.resize({ x = step, y = 0, relative = true }), repeating)
lib.bind(k("ALT + up"),    hl.dsp.window.resize({ x = 0, y = -step, relative = true }), repeating)
lib.bind(k("ALT + down"),  hl.dsp.window.resize({ x = 0, y = step, relative = true }), repeating)

lib.bind(k("mouse:272"), hl.dsp.window.drag(), { mouse = true })
lib.bind(k("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Resize mode: arrows (or hjkl) resize until Escape or Return.
hl.define_submap("resize", function()
    for key, d in pairs({ left = { -step, 0 }, right = { step, 0 }, up = { 0, -step }, down = { 0, step },
                          h = { -step, 0 }, l = { step, 0 }, k = { 0, -step }, j = { 0, step } }) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), repeating)
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
lib.bind(k("R"), hl.dsp.submap("resize"))

-- Groups (tabbed windows).
lib.bind(k("G"), hl.dsp.group.toggle())
lib.bind(k("bracketleft"), hl.dsp.group.prev(), repeating)
lib.bind(k("bracketright"), hl.dsp.group.next(), repeating)

-- Cycle the tiling layout: dwindle → master → scrolling.
local layouts = { "dwindle", "master", "scrolling" }
lib.bind(k("backslash"), function()
    local current = hl.get_config("general.layout")
    local next_layout = layouts[1]
    for i, name in ipairs(layouts) do
        if name == current then next_layout = layouts[i % #layouts + 1] end
    end
    hl.config({ general = { layout = next_layout } })
    hl.notification.create({ text = "Layout: " .. next_layout, timeout = 1500, icon = 1 })
end)

---------------------------------------------------------------- workspaces

for i = 1, 10 do
    local key = tostring(i % 10)
    lib.bind(k(key), hl.dsp.focus({ workspace = i }))
    lib.bind(k("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
    lib.bind(k("ALT + " .. key), hl.dsp.window.move({ workspace = i, follow = false }))
end
lib.bind(k("CTRL + left"),  hl.dsp.focus({ workspace = "r-1" }), repeating)
lib.bind(k("CTRL + right"), hl.dsp.focus({ workspace = "r+1" }), repeating)
lib.bind(k("CTRL + SHIFT + left"),  hl.dsp.window.move({ workspace = "r-1" }))
lib.bind(k("CTRL + SHIFT + right"), hl.dsp.window.move({ workspace = "r+1" }))
lib.bind(k("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
lib.bind(k("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))
lib.bind(k("comma"), hl.dsp.focus({ monitor = "+1" }))
lib.bind(k("SHIFT + comma"), hl.dsp.window.move({ monitor = "+1" }))

-- Special workspaces: the scratchpad, and one per vars.specials entry.
lib.bind(k("S"), hl.dsp.workspace.toggle_special("scratchpad"))
lib.bind(k("ALT + S"), hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
for name, spec in pairs(vars.specials) do
    if spec and spec.key then
        lib.bind(k("ALT + " .. spec.key), hl.dsp.workspace.toggle_special(name))
    end
end
