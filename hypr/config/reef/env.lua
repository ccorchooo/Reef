-- Environment for apps started from Hyprland: Wayland first everywhere, with X11 as
-- the fallback, plus the cursor and NVIDIA's variables.
local lib  = require("reef.lib")
local vars = require("reef.vars")

local env = {
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE    = "wayland",
    XDG_SESSION_DESKTOP = "Hyprland",

    -- Toolkits
    GDK_BACKEND                         = "wayland,x11,*",
    QT_QPA_PLATFORM                     = "wayland;xcb",
    QT_QPA_PLATFORMTHEME                = "qt6ct",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    QT_AUTO_SCREEN_SCALE_FACTOR         = "1",
    SDL_VIDEODRIVER                     = "wayland,x11",
    CLUTTER_BACKEND                     = "wayland",
    ELECTRON_OZONE_PLATFORM_HINT        = "auto",
    MOZ_ENABLE_WAYLAND                  = "1",
    _JAVA_AWT_WM_NONREPARENTING         = "1",

    -- Cursor
    XCURSOR_SIZE    = tostring(vars.cursor.size),
    HYPRCURSOR_SIZE = tostring(vars.cursor.size),
}

if vars.cursor.theme then
    env.XCURSOR_THEME    = vars.cursor.theme
    env.HYPRCURSOR_THEME = vars.cursor.theme
end

-- qt6ct only when it's installed, or Qt apps lose their theme.
if not lib.which({ "qt6ct" }) then
    env.QT_QPA_PLATFORMTHEME = nil
end

local nvidia = vars.nvidia
if nvidia == "auto" then
    nvidia = lib.exists("/proc/driver/nvidia/version")
end
if nvidia then
    env.LIBVA_DRIVER_NAME          = "nvidia"
    env.__GLX_VENDOR_LIBRARY_NAME  = "nvidia"
    env.NVD_BACKEND                = "direct"
end

for name, value in pairs(env) do
    hl.env(name, value)
end
