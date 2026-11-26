-- Small helpers shared by the modules. Pure Lua: no programs run at load time, so a
-- config reload stays instant.
local M = {}

M.home       = os.getenv("HOME") or ""
M.config_dir = (debug.getinfo(1, "S").source:match("^@(.*/)reef/lib%.lua$"))
    or (M.home .. "/.config/hypr/")

function M.exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

function M.read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local text = f:read("a")
    f:close()
    return text
end

-- Create `path` with `content` unless it exists (its folder too).
function M.ensure(path, content)
    if M.exists(path) then return end
    os.execute("mkdir -p '" .. path:match("^(.*)/") .. "'")
    local f = io.open(path, "w")
    if not f then return end
    f:write(content or "return {}\n")
    f:close()
end

-- The first of `candidates` whose program is on PATH (a candidate may carry
-- arguments: "kitty --single-instance"), or nil.
function M.which(candidates)
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    for _, c in ipairs(candidates) do
        local bin = c:match("^(%S+)")
        if bin:sub(1, 1) == "/" then
            if M.exists(bin) then return c end
        else
            for dir in path:gmatch("[^:]+") do
                if M.exists(dir .. "/" .. bin) then return c end
            end
        end
    end
    return nil
end

local function is_list(t)
    return type(t) == "table" and (#t > 0 or next(t) == nil)
end

-- Tables merge key by key; lists and plain values in `over` replace those in `base`.
-- `false` in `over` is kept (it turns things off).
function M.merge(base, over)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        if type(v) == "table" and type(out[k]) == "table" and not is_list(v) and not is_list(out[k]) then
            out[k] = M.merge(out[k], v)
        else
            out[k] = v
        end
    end
    return out
end

-- Bind one key or several to the same action. A key that is nil, false or "" is
-- skipped, so a user can turn a bind off in user/variables.lua.
function M.bind(keys, action, opts)
    if type(keys) ~= "table" then keys = { keys } end
    for _, key in ipairs(keys) do
        if type(key) == "string" and key:match("%S") then
            hl.bind(key, action, opts)
        end
    end
end

-- Problems are shown once Hyprland is up (a notification at load time would be lost
-- on a reload, and `Hyprland --verify-config` has nowhere to show it).
local problems = {}
function M.problem(text)
    problems[#problems + 1] = text
end
hl.on("hyprland.start", function()
    for _, text in ipairs(problems) do
        hl.notification.create({ text = "Reef: " .. text, timeout = 10000, icon = 2 })
    end
end)

-- Reef's own Hyprland snippet (reef.lua: starts the shell, binds its keys, its layer
-- rules) and design tokens (tokens.lua: gaps, corners, springs). Looked for in
-- vars.reefHypr, the installer's link (reef-shell/) and the package's folder; the
-- tokens fall back to the copy installed beside this config.
function M.load_shell()
    local vars = require("reef.vars")
    local dirs = { vars.reefHypr, M.config_dir .. "reef-shell/", "/usr/share/reef/hypr/" }
    for _, dir in ipairs(dirs) do
        if type(dir) == "string" and dir ~= "" then
            if dir:sub(-1) ~= "/" then dir = dir .. "/" end
            if M.exists(dir .. "reef.lua") then
                package.loaded["reef.tokens"] = dofile(dir .. "tokens.lua")
                M.shell_dir = dir
                if vars.shell ~= false then dofile(dir .. "reef.lua") end
                return true
            end
        end
    end
    package.loaded["reef.tokens"] = dofile(M.config_dir .. "reef/tokens.lua")
    if vars.shell ~= false then
        M.problem("Reef's shell snippet wasn't found; Hyprland runs without the shell. Run ./install.sh --hypr-config from Reef.")
    end
    return false
end

-- "rrggbb" + alpha "aa" → "rgba(rrggbbaa)"
function M.rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return M
