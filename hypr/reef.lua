-- Reef for Hyprland (Lua config, Hyprland 0.57+).
--
-- Load it from your config, e.g. at the end of hyprland.lua or a user file:
--     dofile(os.getenv("HOME") .. "/Documents/Reef/hypr/reef.lua")
--
-- Don't load it while another shell (Caelestia) is running: it starts Reef and takes
-- the same keys. Design values come from tokens.lua, generated from design/tokens.json.

local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
local t = dofile(here .. "tokens.lua")

-- Windows share the cays' rhythm (DESIGN.md §4): gaps_in = space-2, gaps_out = space-4,
-- rounding = radius-lg.
hl.config({
    general = {
        gaps_in  = t.gaps_in,
        gaps_out = t.gaps_out,
    },
    decoration = {
        rounding = t.rounding,
    },
})

-- Start the shell. `-n` keeps a second copy from starting on config reload.
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c reef -n -d")
end)

-- Default keybinds (SURFACES.md → Keybinds). Each fires a Reef global shortcut
-- (reef/modules/Commands.qml); actions that aren't built yet just log.
local binds = {
    -- Tap either Super key on its own for search. Release binds fire only when no other
    -- key was pressed while Super was held, so Super+V and friends don't open it.
    { "SUPER + SUPER_L",     "search", { release = true } },
    { "SUPER + SUPER_R",     "search", { release = true } },
    { "SUPER + V",           "clipboard" },
    { "SUPER + period",      "emoji" },
    { "SUPER + C",           "coral" },
    { "SUPER + N",           "controlCenter" },
    { "SUPER + Tab",         "overview" },
    { "ALT + Tab",           "switcher" },
    { "SUPER + E",           "editMode" },
    { "SUPER + L",           "lock" },
    { "CTRL + ALT + Delete", "power" },
    { "SUPER + B",           "focusBar" },
    { "SUPER + I",           "island" },
    { "SUPER + SHIFT + I",   "islandSwap" },
    -- Media keys: Reef changes the level and shows the OSD.
    { "XF86AudioRaiseVolume",  "volumeUp",       { locked = true, repeating = true } },
    { "XF86AudioLowerVolume",  "volumeDown",     { locked = true, repeating = true } },
    { "XF86AudioMute",         "volumeMute",     { locked = true } },
    { "XF86MonBrightnessUp",   "brightnessUp",   { locked = true, repeating = true } },
    { "XF86MonBrightnessDown", "brightnessDown", { locked = true, repeating = true } },
}

for _, b in ipairs(binds) do
    hl.bind(b[1], hl.dsp.global("reef:" .. b[2]), b[3])
end
