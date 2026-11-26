-- What starts with Hyprland. Reef itself and clipboard history start from reef.lua;
-- Reef is the notification server and (Settings → Power) the polkit agent, so neither
-- is started here.
local lib  = require("reef.lib")
local vars = require("reef.vars")

hl.on("hyprland.start", function()
    -- Portals and systemd services need the session's environment (uwsm does this
    -- itself; doing it again is harmless).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")

    if lib.which({ "gnome-keyring-daemon" }) then
        hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    end
    -- Bluetooth headphones' buttons control the player (bluez).
    if lib.which({ "mpris-proxy" }) then
        hl.exec_cmd("mpris-proxy")
    end

    local c = vars.cursor
    if c.theme then
        hl.exec_cmd("hyprctl setcursor " .. c.theme .. " " .. c.size)
        hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme '" .. c.theme .. "'")
        hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. c.size)
    end

    for _, cmd in ipairs(vars.autostart) do
        hl.exec_cmd(cmd)
    end
end)
