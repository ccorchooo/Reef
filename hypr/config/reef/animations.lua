-- Windows move on Reef's own M3 Expressive springs (MOTION.md), so the compositor and
-- the shell feel like one thing: spatial springs (with a little bounce) for anything
-- that moves or resizes, the bezier fallbacks of the effects springs (no bounce) for
-- fades and colors. The values come from tokens.lua, generated from design/tokens.json.
local vars = require("reef.vars")
local t    = require("reef.tokens")
local s    = t.springs

hl.config({ animations = { enabled = vars.animations.enabled, workspace_wraparound = false } })

-- A spring from a Reef token. Hyprland takes the damping coefficient, Reef keeps the
-- damping ratio: c = 2 * ratio * sqrt(stiffness * mass).
local function spring(name, token)
    local sp = s[token]
    hl.curve(name, { type = "spring", mass = 1, stiffness = sp.stiffness, damping = 2 * sp.damping * math.sqrt(sp.stiffness) })
end
-- A token's bezier fallback.
local function bezier(name, token)
    local b = s[token].bezier
    hl.curve(name, { type = "bezier", points = { { b[1], b[2] }, { b[3], b[4] } } })
end
-- Hyprland's speed is in tenths of a second.
local function speed(token) return s[token].duration / 100 end

spring("spatialFast", "spatial-fast")
spring("spatialDefault", "spatial-default")
spring("spatialSlow", "spatial-slow")
bezier("effectsFast", "effects-fast")
bezier("effectsDefault", "effects-default")
bezier("effectsSlow", "effects-slow")

local a = vars.animations
local function anim(leaf, curve, token, style)
    local spec = { leaf = leaf, enabled = true, speed = speed(token), style = style }
    if curve:match("^spatial") then spec.spring = curve else spec.bezier = curve end
    hl.animation(spec)
end

-- Windows: open and move with spatial-default; close quickly, without bounce.
anim("windows",      "spatialDefault", "spatial-default")
anim("windowsIn",    "spatialDefault", "spatial-default", a.window_style)
anim("windowsOut",   "effectsDefault", "effects-default", a.window_style)
anim("windowsMove",  "spatialDefault", "spatial-default")

-- Fades: opacity, dimming, borders.
anim("fade",         "effectsDefault", "effects-default")
anim("fadeIn",       "effectsDefault", "effects-default")
anim("fadeOut",      "effectsFast",    "effects-fast")
anim("fadeSwitch",   "effectsDefault", "effects-default")
anim("fadeShadow",   "effectsDefault", "effects-default")
anim("fadeDim",      "effectsSlow",    "effects-slow")
anim("border",       "effectsSlow",    "effects-slow")

-- Layers that aren't Reef's (Reef animates its own; reef.lua turns these off for reef-*).
anim("layers",       "spatialDefault", "spatial-default", "fade")
anim("fadeLayersIn", "effectsDefault", "effects-default")
anim("fadeLayersOut","effectsFast",    "effects-fast")

-- Workspaces slide on spatial-default (Reef's overview waits for this slide to end, reading
-- its length from `hyprctl animations`); special workspaces drop in from above.
anim("workspaces",       "spatialDefault", "spatial-default", a.workspace_style)
anim("specialWorkspace", "spatialDefault", "spatial-default", "slidefadevert -20%")

anim("zoomFactor",   "effectsDefault", "effects-default")
