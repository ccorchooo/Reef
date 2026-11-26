-- Window colors from Reef's scheme: the active border is the primary (Reef's one
-- accent), inactive ones the outline, faint; groups use the secondary.
--
-- At load the colors come from Reef's cache (~/.cache/reef/scheme.json) in the mode
-- Reef's config asks for. After that Reef pushes them live whenever its scheme or
-- light/dark changes (services/CompositorTheme: `hyprctl eval reef_apply_colors(…)`),
-- so a new wallpaper recolors the borders without reloading this config.
local lib  = require("reef.lib")
local vars = require("reef.vars")
local look = vars.look
local t    = require("reef.tokens")


-- Light or dark, as Reef's config says (look.theme: dark | light | auto).
local function reef_mode()
    local text = lib.read(lib.home .. "/.config/reef/config.json") or ""
    local block = text:match('"look"%s*:%s*(%b{})') or ""
    local theme = block:match('"theme"%s*:%s*"(%a+)"') or "dark"
    if theme ~= "auto" then return theme end
    local function minutes(s)
        local h, m = (s or ""):match("(%d+):(%d+)")
        return h and (tonumber(h) * 60 + tonumber(m)) or nil
    end
    local light = minutes(block:match('"autoLightAt"%s*:%s*"([%d:]+)"')) or 7 * 60
    local dark  = minutes(block:match('"autoDarkAt"%s*:%s*"([%d:]+)"')) or 19 * 60
    local now = os.date("*t")
    now = now.hour * 60 + now.min
    local is_light = light <= dark and (now >= light and now < dark) or (light > dark and (now >= light or now < dark))
    return is_light and "light" or "dark"
end

-- The roles of `mode` from Reef's cached scheme ({ dark = { role = "#hex" }, light = … }).
local function cached_roles(mode)
    local text = lib.read(lib.home .. "/.cache/reef/scheme.json")
    local block = text and text:match('"' .. mode .. '"%s*:%s*(%b{})')
    if not block then return nil end
    local roles = {}
    for k, v in block:gmatch('"(%w+)"%s*:%s*"#(%x%x%x%x%x%x)') do
        roles[k] = v:lower()
    end
    return next(roles) and roles or nil
end

-- Global, so Reef can call it through `hyprctl eval`. roles: { primary = "rrggbb", … }
function reef_apply_colors(mode, roles)
    -- Missing roles come from Reef's reference scheme (tokens.json).
    local r = setmetatable(roles or {}, { __index = t.scheme[mode] or t.scheme.dark })
    local shadow_alpha = mode == "light" and look.shadow.alpha_light or look.shadow.alpha_dark
    hl.config({
        general = {
            col = {
                active_border   = lib.rgba(r.primary),
                inactive_border = lib.rgba(r.outline, look.inactive_border_alpha),
            },
        },
        decoration = {
            shadow = {
                color          = lib.rgba("000000", shadow_alpha),
                color_inactive = lib.rgba("000000", string.format("%02x", math.floor(tonumber(shadow_alpha, 16) / 2))),
            },
        },
        group = {
            col = {
                border_active          = lib.rgba(r.secondary),
                border_inactive        = lib.rgba(r.outline, look.inactive_border_alpha),
                border_locked_active   = lib.rgba(r.tertiary),
                border_locked_inactive = lib.rgba(r.outline, look.inactive_border_alpha),
            },
            groupbar = {
                text_color          = lib.rgba(r.onSurface),
                text_color_inactive = lib.rgba(r.onSurfaceVariant),
                col = {
                    active          = lib.rgba(r.surfaceContainerHigh),
                    inactive        = lib.rgba(r.surfaceContainer),
                    locked_active   = lib.rgba(r.surfaceContainerHigh),
                    locked_inactive = lib.rgba(r.surfaceContainer),
                },
            },
        },
        misc = {
            background_color = lib.rgba(r.surface),
        },
    })
end

local mode = reef_mode()
reef_apply_colors(mode, cached_roles(mode))
