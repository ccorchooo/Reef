-- Window, workspace and layer rules. Dialogs and small tools float at sensible sizes,
-- media and chat apps go to their own special workspaces, games get tearing and keep
-- the screen awake, and a handful of fixes for Xwayland and picture-in-picture.
local vars = require("reef.vars")
local t    = require("reef.tokens")

local function rule(name, match, effects)
    effects.name  = name
    effects.match = match
    hl.window_rule(effects)
end

-- Several matches with the same effects (one rule each; Hyprland's match fields AND).
local function rules(name, field, patterns, effects)
    for i, pattern in ipairs(patterns) do
        local e = {}
        for k, v in pairs(effects) do e[k] = v end
        rule(name .. "-" .. i, { [field] = pattern }, e)
    end
end

local function sized(w, h)
    return { float = true, center = true, size = "(monitor_w*" .. w .. ") (monitor_h*" .. h .. ")" }
end

---------------------------------------------------------------- everything

-- Apps don't maximize themselves; the layout decides.
rule("no-maximize-requests", { class = ".*" }, { suppress_event = "maximize" })
-- Anything fullscreen (a video, a game) keeps the screen awake.
rule("fullscreen-stays-awake", { class = ".*" }, { idle_inhibit = "fullscreen" })
-- Floating windows open centered on their monitor.
rule("center-floating", { float = true, xwayland = false }, { center = true })

---------------------------------------------------------------- floating

rules("float-apps", "class", {
    "^(org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    "^(blueman-manager|.blueman-manager-wrapped)$",
    "^(nm-connection-editor|nm-applet)$",
    "^(org.gnome.FileRoller|file-roller|xarchiver)$",
    "^(org.gnome.Calculator|qalculate-gtk|kcalc)$",
    "^(imv|feh|swappy|org.gnome.Loupe)$",
    "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde)$",
    "^(polkit-gnome-authentication-agent-1|org.kde.polkit-kde-authentication-agent-1)$",
    "^(nwg-look|qt5ct|qt6ct|kvantummanager)$",
    "^(wev|yad|zenity)$",
}, { float = true })

rules("float-dialogs", "title", {
    "^(Open|Save|Select|Choose)( a| an)? (File|Files|Folder|Directory|Image)",
    "^(Save As|Export|Import)",
    "^File (Operation|Upload)( Progress)?",
    ".* Properties$",
    "^Rename .*",
}, sized(0.6, 0.7))

-- Reef's own windows (Settings sizes itself; reef.lua floats it).
rule("reef-coral", { class = "^(org.quickshell|quickshell)$", title = "^Coral$" }, { float = true, center = true })

-- Picture in picture: small, pinned, bottom right, aspect kept.
rule("pip", { title = "^(Picture[- ]in[- ][Pp]icture)$" }, {
    float = true, pin = true, keep_aspect_ratio = true,
    size  = "(monitor_w*0.25) (monitor_w*0.25*9/16)",
    move  = "(monitor_w-window_w-" .. t["space-4"] .. ") (monitor_h-window_h-" .. t["space-12"] .. "*2)",
})

---------------------------------------------------------------- games

rules("games", "class", { "^steam_app_[0-9]+$", "^(steam_app_default|gamescope|osu!|Minecraft.*)$" }, {
    immediate = true, idle_inhibit = "always", no_blur = true, opaque = true,
})
rule("steam-friends", { class = "^steam$", title = "^Friends List$" }, sized(0.2, 0.6))

---------------------------------------------------------------- special workspaces

for name, spec in pairs(vars.specials) do
    if spec then
        for i, class in ipairs(spec.classes or {}) do
            rule("special-" .. name .. "-class-" .. i, { class = "^(" .. class .. ")$" }, { workspace = "special:" .. name .. " silent" })
        end
        for i, title in ipairs(spec.titles or {}) do
            rule("special-" .. name .. "-title-" .. i, { initial_title = "^(" .. title .. ")$" }, { workspace = "special:" .. name .. " silent" })
        end
    end
end

---------------------------------------------------------------- fixes

-- Xwayland drag-and-drop helpers and empty popups shouldn't take focus or decoration.
rule("xwayland-drag", { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })
rule("xwayland-popups", { xwayland = true, title = "^win[0-9]+$" }, {
    no_shadow = true, no_blur = true, no_dim = true, rounding = t["radius-sm"],
})
-- Browser sharing indicators float out of the way.
rule("share-indicator", { title = ".*is sharing (your screen|a window)\\.$" }, { float = true, pin = true, move = "(monitor_w*0.5-window_w*0.5) " .. t["space-4"] })

---------------------------------------------------------------- workspaces

-- The scratchpad and the special workspaces keep their windows when hidden.
hl.workspace_rule({ workspace = "special:scratchpad", gaps_out = t["space-12"] })

---------------------------------------------------------------- layers

-- Region and color pickers fade instead of sliding.
for _, ns in ipairs({ "selection", "hyprpicker", "wayfreeze" }) do
    hl.layer_rule({ name = "fade-" .. ns, match = { namespace = "^" .. ns .. "$" }, animation = "fade" })
end
-- Other launchers and bars get Hyprland's blur behind them.
hl.layer_rule({ name = "blur-launchers", match = { namespace = "^(launcher|rofi|fuzzel|walker|anyrun)$" }, blur = true, ignore_alpha = 0.3, animation = "popin 90%" })
