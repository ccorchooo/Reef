-- Monitors: every output at its preferred mode, placed automatically, at its own
-- scale; then yours from vars.monitors (they win, being later).
local vars = require("reef.vars")

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

for _, spec in ipairs(vars.monitors) do
    hl.monitor(spec)
end
