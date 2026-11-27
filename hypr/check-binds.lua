-- Checks a Reef Hyprland config for keys bound twice.
--
--   lua hypr/check-binds.lua [config dir] [--list]
--
-- Loads the config's hyprland.lua (default ~/.config/hypr) with a stand-in `hl` that only
-- records binds, so it runs anywhere, with no Hyprland. Two binds clash when they share
-- the submap, the modifiers, the key and whether they fire on release. Exit 1 on a clash.
-- `reef doctor` runs it; Hyprland's own `--verify-config` checks everything else.

local dir, list = nil, false
for _, a in ipairs(arg) do
    if a == "--list" then list = true else dir = a end
end
dir = dir or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
if dir:sub(-1) ~= "/" then dir = dir .. "/" end

local binds, submap = {}, "global"

-- Anything not stubbed below is a callable, indexable no-op.
local function noop()
    return setmetatable({}, {
        __index = function() return noop() end,
        __call = function() return noop() end,
    })
end

local hl = {
    bind = function(key, action, opts)
        binds[#binds + 1] = { key = key, opts = opts or {}, submap = submap, action = action,
                              where = debug.getinfo(2, "Sl") }
    end,
    unbind = function(key)
        for i = #binds, 1, -1 do
            if binds[i].key == key and binds[i].submap == submap then table.remove(binds, i) end
        end
    end,
    define_submap = function(name, fn)
        local before = submap
        submap = name
        fn()
        submap = before
    end,
    get_config = function() return nil end,
    get_active_window = function() return nil end,
    get_active_workspace = function() return nil end,
    get_active_monitor = function() return nil end,
    get_workspace = function() return nil end,
    version = function() return "0.57" end,
    on = function() end,
    dsp = setmetatable({}, {
        __index = function(_, name)
            local function dispatcher(path)
                return setmetatable({}, {
                    __index = function(_, sub) return dispatcher(path .. "." .. sub) end,
                    __call = function(_, args)
                        local s = path
                        if type(args) == "string" then s = s .. "(" .. args .. ")" end
                        return { dsp = s }
                    end,
                })
            end
            return dispatcher(name)
        end,
    }),
}
setmetatable(hl, { __index = function() return noop() end })
_G.hl = hl

package.path = dir .. "?.lua;" .. package.path
local ok, err = pcall(dofile, dir .. "hyprland.lua")
if not ok then
    io.stderr:write("check-binds: the config didn't load: " .. tostring(err) .. "\n")
    os.exit(2)
end

local MODS = { SUPER = "SUPER", WIN = "SUPER", LOGO = "SUPER", MOD4 = "SUPER", SHIFT = "SHIFT",
               CTRL = "CTRL", CONTROL = "CTRL", ALT = "ALT", MOD1 = "ALT" }
-- "SUPER + SHIFT + 1" → "SHIFT+SUPER+1": every part but the last is a modifier.
local function normal(key)
    local parts = {}
    for part in key:gmatch("[^+]+") do parts[#parts + 1] = part:match("^%s*(.-)%s*$") end
    local k = table.remove(parts):lower()
    local set = {}
    for _, p in ipairs(parts) do set[MODS[p:upper()] or p:upper()] = true end
    local names = {}
    for m in pairs(set) do names[#names + 1] = m end
    table.sort(names)
    return table.concat(names, "+") .. (#names > 0 and "+" or "") .. k
end

local function describe(b)
    local a = type(b.action) == "table" and b.action.dsp or (type(b.action) == "function" and "lua function") or "?"
    local where = b.where and (b.where.short_src:gsub("^.*/hypr/", "") .. ":" .. b.where.currentline) or ""
    return string.format("%-34s %-26s %s", b.key, a, where)
end

local seen, clashes = {}, 0
for _, b in ipairs(binds) do
    local id = b.submap .. "|" .. normal(b.key) .. "|" .. (b.opts.release and "release" or "press")
    if seen[id] then
        clashes = clashes + 1
        print("clash: " .. b.key .. (b.submap ~= "global" and (" (submap " .. b.submap .. ")") or ""))
        print("    " .. describe(seen[id]))
        print("    " .. describe(b))
    else
        seen[id] = b
    end
end

if list then
    table.sort(binds, function(a, b) return normal(a.key) < normal(b.key) end)
    for _, b in ipairs(binds) do
        print((b.submap ~= "global" and ("[" .. b.submap .. "] ") or "") .. describe(b))
    end
end
print(string.format("%d binds, %d clash%s", #binds, clashes, clashes == 1 and "" or "es"))
os.exit(clashes == 0 and 0 or 1)
