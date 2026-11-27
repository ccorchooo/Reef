-- This config's keys, laid out like Caelestia's. Reef's own keys (search on a Super tap,
-- the Island, Coral, the control center, overview, Alt+Tab, lock, power, screenshots,
-- recording, media and brightness keys) are in reef.lua, and none of them is repeated
-- here. Every key below comes from vars.keys (reef/variables.lua), so user/variables.lua
-- can move or free any of them; `reef doctor` (scripts/check-binds.lua) checks that no
-- two binds share a key.
--
--   SUPER + Return / T      terminal              SUPER + 1…0             go to workspace
--   SUPER + W               browser               SUPER + ALT + 1…0       move window there
--   SUPER + C               editor                SUPER + SHIFT + 1…0     send window there, stay
--   SUPER + E               files                 CTRL + SUPER + 1…0      workspace group 1…10
--   CTRL + ALT + V          volume mixer          SUPER + scroll / PgUp/Dn, CTRL + SUPER + ←/→
--   SUPER + SHIFT + C       color picker                                  previous / next workspace
--   CTRL + SHIFT + Escape   system monitor        SUPER + ALT + scroll / PgUp/Dn  move window along
--   SUPER + Q               close window          SUPER + S               scratchpad
--   SUPER + SHIFT + Q       kill window           SUPER + ALT + S         window to the scratchpad
--   SUPER + F / ALT + F     fullscreen / maximize SUPER + M / D / R       music / chat / to-do
--   SUPER + ALT + Space     float (SUPER+SHIFT+F) SUPER + O / SHIFT + O   other monitor / move there
--   SUPER + P               pin                   SUPER + comma / G       group / ungroup (SUPER + U)
--   SUPER + ALT + \         picture in picture    CTRL + ALT + Tab        next window in the group
--   CTRL + SUPER + \        center                SUPER + Z / X (+ mouse) move / resize
--   SUPER + arrows          focus                 SUPER + -/= (+ SHIFT)   narrower, wider (shorter, taller)
--   SUPER + SHIFT + arrows  move window           SUPER + SHIFT + R       resize mode (arrows, Esc)
--   SUPER + ALT + arrows    resize                SUPER + J / \           split / next layout
--   CTRL + SUPER + R        restart Reef          SUPER + ALT + L         restore the lock (after a crash)
local vars = require("reef.vars")
local lib  = require("reef.lib")
local keys = vars.keys or {}
local apps = vars.apps

local repeating = { repeating = true }
local mouse     = { mouse = true }
local locked    = { locked = true }

-- Repeating, unless it's a scroll ("mouse_down") bind, which repeats on its own.
local function repeats(key)
    return key:lower():find("mouse", 1, true) and nil or repeating
end
local function bind_each(k, action, opts_for)
    if type(k) ~= "table" then k = { k } end
    for _, key in ipairs(k) do
        if type(key) == "string" and key:match("%S") then
            hl.bind(key, action, opts_for and opts_for(key) or nil)
        end
    end
end
local function exec(cmd) return cmd and hl.dsp.exec_cmd(cmd) end

---------------------------------------------------------------- apps

lib.bind(keys.terminal, exec(apps.terminal))
lib.bind(keys.browser, exec(apps.browser))
if apps.editor then lib.bind(keys.editor, exec(apps.editor)) end
lib.bind(keys.files, exec(apps.files))
if apps.audio then lib.bind(keys.audio, exec(apps.audio)) end
if apps.picker then lib.bind(keys.picker, exec(apps.picker)) end

-- The system monitor, in a terminal of its own on the sysmon special workspace.
if apps.monitor then
    local term = apps.terminal:match("^(%S+)")
    local cmd = term == "kitty" and ("kitty --class reef-sysmon -T 'System monitor' " .. apps.monitor)
        or term == "foot" and ("foot -a reef-sysmon -T 'System monitor' " .. apps.monitor)
        or (apps.terminal .. " -e " .. apps.monitor)
    vars.specials.sysmon = vars.specials.sysmon and lib.merge(vars.specials.sysmon, { key = keys.sysmon, exec = cmd })
end

-- Reef itself: restart (after an update, or if it misbehaves), stop, and the lock's
-- recovery after a crash (start Reef again, then lock).
lib.bind(keys.restartShell, exec("qs kill -c reef; qs -c reef -n -d"))
lib.bind(keys.killShell, exec("qs kill -c reef"), { release = true })
lib.bind(keys.restoreLock, exec("qs -c reef -n -d; sleep 1; qs -c reef ipc call lock lock"), locked)

-- Type the newest clipboard entry (wtype), for fields that refuse a paste.
if lib.which({ "wtype" }) then
    lib.bind(keys.pasteLatest, exec("sleep 0.3; wtype \"$(cliphist list | head -1 | cliphist decode)\""), locked)
end
lib.bind(keys.testNotification, exec(
    "notify-send -a Reef -A 'ok=Got it' -A 'later=Another action' 'Test notification' " ..
    "'A longer message, to see how notifications wrap and truncate across more than one line.'"))

---------------------------------------------------------------- windows

lib.bind(keys.close, hl.dsp.window.close())
lib.bind(keys.kill, hl.dsp.window.kill())
lib.bind(keys.fullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
lib.bind(keys.maximize, hl.dsp.window.fullscreen({ mode = "maximized" }))
lib.bind(keys.float, function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    local w = hl.get_active_window()
    if w and w.floating then hl.dispatch(hl.dsp.window.center()) end
end)
lib.bind(keys.pin, hl.dsp.window.pin())
lib.bind(keys.center, hl.dsp.window.center())
lib.bind(keys.togglesplit, hl.dsp.layout("togglesplit"))

-- The active window, as a share of its monitor (logical pixels).
local function screen_size()
    local m = hl.get_active_monitor()
    if not (m and type(m.width) == "number") then return nil end
    local s = m.scale or 1
    return m.width / s, m.height / s, m
end

-- Normalize: float at 55% × 70% of the screen, centered.
lib.bind(keys.normalize, function()
    local w, h = screen_size()
    local win = hl.get_active_window()
    if not (w and win) then return end
    if not win.floating then hl.dispatch(hl.dsp.window.float()) end
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * 0.55), y = math.floor(h * 0.7), relative = false }))
    hl.dispatch(hl.dsp.window.center())
end)

-- Picture in picture: float, a quarter of the screen's height, bottom right, pinned.
lib.bind(keys.pip, function()
    local w, h, m = screen_size()
    local win = hl.get_active_window()
    if not (w and win and win.size) then return end
    if not win.floating then hl.dispatch(hl.dsp.window.float()) end
    local f = (h / 4) / win.size.y
    local ww, wh = math.max(200, math.floor(win.size.x * f)), math.max(150, math.floor(win.size.y * f))
    local gap = math.floor(math.min(w, h) * 0.03)
    local addr = "address:" .. win.address
    hl.dispatch(hl.dsp.window.resize({ x = ww, y = wh, relative = false, window = addr }))
    hl.dispatch(hl.dsp.window.move({ x = math.floor((m.x or 0) + w - ww - gap), y = math.floor((m.y or 0) + h - wh - gap), relative = false, window = addr }))
    hl.dispatch(hl.dsp.window.pin({ action = "on", window = addr }))
end)

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
    hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Resize by a share of the window (10%), like Caelestia.
local function grow(dx, dy)
    return function()
        local win = hl.get_active_window()
        if not (win and win.size) then return end
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(win.size.x * dx), y = math.floor(win.size.y * dy), relative = true }))
    end
end
bind_each(keys.narrower, grow(-0.1, 0), function() return repeating end)
bind_each(keys.wider, grow(0.1, 0), function() return repeating end)
bind_each(keys.shorter, grow(0, -0.1), function() return repeating end)
bind_each(keys.taller, grow(0, 0.1), function() return repeating end)

lib.bind({ "SUPER + mouse:272", keys.dragKey }, hl.dsp.window.drag(), mouse)
lib.bind({ "SUPER + mouse:273", keys.resizeKey }, hl.dsp.window.resize(), mouse)

-- Resize mode: arrows (or hjkl) resize until Escape or Return.
local step = 40
hl.define_submap("resize", function()
    for key, d in pairs({ left = { -step, 0 }, right = { step, 0 }, up = { 0, -step }, down = { 0, step },
                          h = { -step, 0 }, l = { step, 0 }, k = { 0, -step }, j = { 0, step } }) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), repeating)
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
lib.bind(keys.resizeMode, hl.dsp.submap("resize"))

-- Groups (tabbed windows).
lib.bind(keys.groupToggle, hl.dsp.group.toggle())
lib.bind(keys.groupLock, hl.dsp.group.lock())
lib.bind(keys.ungroup, hl.dsp.window.move({ out_of_group = true }))
lib.bind(keys.groupNext, hl.dsp.group.next(), repeating)
lib.bind(keys.groupPrev, hl.dsp.group.prev(), repeating)

-- Cycle the tiling layout: dwindle → master → scrolling.
local layouts = { "dwindle", "master", "scrolling" }
lib.bind(keys.nextLayout, function()
    local current = hl.get_config("general.layout")
    local next_layout = layouts[1]
    for i, name in ipairs(layouts) do
        if name == current then next_layout = layouts[i % #layouts + 1] end
    end
    hl.config({ general = { layout = next_layout } })
    hl.notification.create({ text = "Layout: " .. next_layout, timeout = 1500, icon = 1 })
end)

---------------------------------------------------------------- workspaces

-- Workspaces come in groups of ten (Caelestia's): 1…0 pick a slot in the current group,
-- and the group keys pick the same slot in another group.
local function ws_action(action, group, i)
    return function()
        local ws = hl.get_active_workspace()
        local id = ws and type(ws.id) == "number" and ws.id >= 1 and ws.id or 1
        local slot = (id - 1) % 10 + 1
        local target = group and ((i - 1) * 10 + slot) or (math.floor((id - 1) / 10) * 10 + i)
        if action == "move" then
            hl.dispatch(hl.dsp.window.move({ workspace = target }))
        elseif action == "send" then
            hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = target }))
        end
    end
end
local function with(mods, key)
    return type(mods) == "string" and mods ~= "" and (mods .. " + " .. key) or nil
end
for i = 1, 10 do
    local key = tostring(i % 10)
    lib.bind(with(vars.mod, key), ws_action("focus", false, i))
    lib.bind(with(keys.moveToWs, key), ws_action("move", false, i))
    lib.bind(with(keys.moveToWsSilent, key), ws_action("send", false, i))
    lib.bind(with(keys.wsGroup, key), ws_action("focus", true, i))
    lib.bind(with(keys.moveToWsGroup, key), ws_action("move", true, i))
end

bind_each(keys.nextWs, hl.dsp.focus({ workspace = "+1" }), repeats)
bind_each(keys.prevWs, hl.dsp.focus({ workspace = "-1" }), repeats)
bind_each(keys.nextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeats)
bind_each(keys.prevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeats)
bind_each(keys.moveToNextWs, hl.dsp.window.move({ workspace = "+1" }), repeats)
bind_each(keys.moveToPrevWs, hl.dsp.window.move({ workspace = "-1" }), repeats)

lib.bind(keys.nextMonitor, hl.dsp.focus({ monitor = "+1" }))
lib.bind(keys.windowToMonitor, hl.dsp.window.move({ monitor = "+1" }))

-- Special workspaces: the scratchpad, and one per vars.specials entry with a key. One
-- that's shown empty starts its app first (`exec`), which lands there by its rule.
lib.bind(keys.scratchpad, hl.dsp.workspace.toggle_special("scratchpad"))
lib.bind(keys.toScratchpad, hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
lib.bind(keys.fromSpecial, hl.dsp.window.move({ workspace = "e+0" }))
for name, spec in pairs(vars.specials) do
    if spec and spec.key then
        lib.bind(spec.key, function()
            local ws = hl.get_workspace("special:" .. name)
            if spec.exec and (not ws or ws.windows == 0) then
                hl.dispatch(hl.dsp.exec_cmd(spec.exec))
            end
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        end)
    end
end
