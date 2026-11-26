-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │ Reef for Hyprland 0.57+ (Lua config)                                         │
-- │                                                                              │
-- │ A whole Hyprland setup around the Reef shell: windows share Reef's rhythm    │
-- │ (gaps, corners), move on Reef's M3 springs and take their border colors from │
-- │ Reef's scheme, live.                                                         │
-- │                                                                              │
-- │   reef/          the config, in modules. Updated by ./install.sh --hypr-config │
-- │   user/          yours, never overwritten:                                   │
-- │     variables.lua  change apps, keyboard, looks… (see reef/variables.lua)      │
-- │     user.lua       anything else: binds, rules, monitors, unbinds            │
-- │   reef-shell/    Reef's own snippet (reef.lua: starts Reef, binds its keys)   │
-- └──────────────────────────────────────────────────────────────────────────────┘

local lib  = require("reef.lib")
local here = lib.config_dir

-- Your files, created from the templates the first time.
lib.ensure(here .. "user/variables.lua", lib.read(here .. "reef/defaults/variables.lua"))
lib.ensure(here .. "user/user.lua", lib.read(here .. "reef/defaults/user.lua"))

-- Settings: the defaults with yours on top. Modules read them as require("reef.vars").
local ok, user_vars = pcall(require, "user.variables")
if not ok then
    print("Reef: user/variables.lua has an error, using the defaults: " .. tostring(user_vars))
    lib.problem("user/variables.lua has an error; using the defaults")
    user_vars = {}
end
package.loaded["reef.vars"] = lib.merge(require("reef.variables"), user_vars or {})

-- Reef's own snippet and design tokens. Without the shell this is still a whole setup.
lib.load_shell()

require("reef.env")
require("reef.monitors")
require("reef.input")
require("reef.look")
require("reef.animations")
require("reef.colors")
require("reef.rules")
require("reef.binds")
require("reef.autostart")

-- Last, so it can change anything above.
local user_ok, err = pcall(require, "user.user")
if not user_ok then
    print("Reef: user/user.lua: " .. tostring(err))
    lib.problem("user/user.lua has an error: " .. tostring(err))
end
