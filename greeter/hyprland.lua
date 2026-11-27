-- The Hyprland that greetd starts for Reef's login greeter (as the greeter user):
--   command = "start-hyprland -- -c /usr/share/reef/greeter/hyprland.lua"
-- It only runs the greeter (qs -p /usr/share/reef/reef/greeter.qml) and leaves when the greeter does,
-- which happens once greetd has started your session.
local shell = os.getenv("REEF_SHELL_DIR") or "/usr/share/reef/reef"

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
    animations = { enabled = false },
    cursor = { inactive_timeout = 0 },
    input = { numlock_by_default = true },
})

-- Reef draws its own entry; no layer animation on top.
hl.layer_rule({ name = "reef-greeter", match = { namespace = "^reef-greeter$" }, no_anim = true })

-- The keyboard layout the installer copied from your desktop, if any.
local f = io.open("/usr/share/reef/greeter/keyboard.lua", "r")
if f then
    f:close()
    local ok, kb = pcall(dofile, "/usr/share/reef/greeter/keyboard.lua")
    if ok and type(kb) == "table" then hl.config({ input = kb }) end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'qs -p " .. shell .. "/greeter.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
