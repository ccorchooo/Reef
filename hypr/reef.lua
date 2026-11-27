-- Reef for Hyprland (Lua config, Hyprland 0.57+).
--
-- Load it from your config, e.g. at the end of hyprland.lua or a user file:
--     dofile(os.getenv("HOME") .. "/Documents/Reef/hypr/reef.lua")   -- a checkout
--     dofile("/usr/share/reef/hypr/reef.lua")                          -- the reef-git package
-- Or use the whole config in hypr/config (./install.sh --hypr-config), which loads this file.
-- (`./install.sh --hypr` adds the checkout's line for you.)
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

-- Reef animates its own surfaces; Hyprland's layer animations would play on top
-- (a slide as the overview or switcher appears, the last frame sliding away as it goes).
hl.layer_rule({ name = "reef", match = { namespace = "^reef-.*" }, no_anim = true })

-- Settings (screens/Settings) floats, centered. Reef sizes it itself (the designed size
-- times the zoom, and again when the zoom changes), so the rule sets no size.
hl.window_rule({
    name   = "reef-settings",
    match  = { class = "^(org\\.quickshell|quickshell)$", title = "^Settings$" },
    float  = true,
    center = true,
})

-- Start the shell. `-n` keeps a second copy from starting on config reload.
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c reef -n -d")
    -- Clipboard history for the Island's Clipboard tab (cliphist + wl-clipboard).
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- Default keybinds (SURFACES.md → Keybinds), laid out to match Caelestia's where the two
-- share an action. Each fires a Reef global shortcut (reef/modules/Commands.qml).
-- In Reef's Hyprland config, user/variables.lua can move or free any of them by action:
--     shellKeys = { coral = "SUPER + Y", editMode = false }
-- A list gives one action several keys. `reef doctor` checks for clashes.
local keys = {
    -- Tap either Super key on its own for search. Release binds fire only when no other
    -- key was pressed while Super was held, so Super+V and friends don't open it.
    search        = { { "SUPER + SUPER_L", "SUPER + SUPER_R" }, { release = true } },
    -- Holding either Super key shows the workspaces in the bar until it's let go (Reef
    -- gets the press and the release of this global; a hold doesn't open search).
    superHold     = { { "SUPER + SUPER_L", "SUPER + SUPER_R" } },
    clipboard     = { { "SUPER + V", "SUPER + ALT + V" } },
    emoji         = { "SUPER + period" },
    coral         = { "SUPER + A" },
    coralApp      = { "SUPER + SHIFT + A" },
    controlCenter = { "SUPER + N" },
    island        = { { "SUPER + I", "SUPER + K" } },
    islandSwap    = { "SUPER + SHIFT + I" },
    overview      = { "SUPER + Tab" },
    -- Hold Alt and press Tab to step through windows; letting go of Alt switches.
    switcher      = { "ALT + Tab", { repeating = true } },
    switcherBack  = { "ALT + SHIFT + Tab", { repeating = true } },
    editMode      = { "SUPER + SHIFT + E" },
    focusBar      = { "SUPER + B" },
    lock          = { "SUPER + L" },
    sleep         = { "SUPER + SHIFT + L", { locked = true } },
    power         = { "CTRL + ALT + Delete" },
    clearNotifications = { "CTRL + ALT + C", { locked = true } },
    -- Screenshots: the screen, or a region (saved and copied; Reef's Screenshot service).
    screenshotScreen = { "Print", { locked = true } },
    screenshot    = { { "SUPER + SHIFT + S", "SUPER + SHIFT + ALT + S" } },
    -- Recording (again to stop): the screen, with sound, or a region.
    record        = { "CTRL + ALT + R" },
    recordSound   = { "SUPER + ALT + R" },
    recordRegion  = { "SUPER + SHIFT + ALT + R" },
    -- Volume, brightness and media: Reef changes the level and shows the OSD.
    volumeUp      = { "XF86AudioRaiseVolume", { locked = true, repeating = true } },
    volumeDown    = { "XF86AudioLowerVolume", { locked = true, repeating = true } },
    volumeMute    = { { "XF86AudioMute", "SUPER + SHIFT + M" }, { locked = true } },
    micMute       = { "XF86AudioMicMute", { locked = true } },
    brightnessUp  = { "XF86MonBrightnessUp", { locked = true, repeating = true } },
    brightnessDown = { "XF86MonBrightnessDown", { locked = true, repeating = true } },
    mediaToggle   = { { "XF86AudioPlay", "XF86AudioPause", "CTRL + SUPER + space" }, { locked = true } },
    mediaNext     = { { "XF86AudioNext", "CTRL + SUPER + equal" }, { locked = true } },
    mediaPrevious = { { "XF86AudioPrev", "CTRL + SUPER + minus" }, { locked = true } },
    mediaStop     = { { "XF86AudioStop", "CTRL + SUPER + BackSpace" }, { locked = true } },
}

local vars = package.loaded["reef.vars"]
local over = type(vars) == "table" and type(vars.shellKeys) == "table" and vars.shellKeys or {}

-- In a fixed order (search's release bind before superHold's press, as always).
local names = {}
for action in pairs(keys) do names[#names + 1] = action end
table.sort(names)
for _, action in ipairs(names) do
    local b = keys[action]
    local k = b[1]
    if over[action] ~= nil then k = over[action] end
    if type(k) ~= "table" then k = { k } end
    for _, key in ipairs(k) do
        if type(key) == "string" and key:match("%S") then
            hl.bind(key, hl.dsp.global("reef:" .. action), b[2])
        end
    end
end
