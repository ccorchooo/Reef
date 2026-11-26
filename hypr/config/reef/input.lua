-- Keyboard, pointer, touchpad and gestures.
local vars = require("reef.vars")
local i    = vars.input

hl.config({
    input = {
        kb_layout          = i.layout,
        kb_variant         = i.variant,
        kb_options         = i.options,
        repeat_rate        = i.repeat_rate,
        repeat_delay       = i.repeat_delay,
        numlock_by_default = i.numlock,
        sensitivity        = i.sensitivity,
        accel_profile      = i.accel ~= "" and i.accel or nil,
        follow_mouse       = i.follow_mouse,
        -- Focus a window only when the pointer really moves onto it.
        mouse_refocus      = false,
        float_switch_override_focus = 0,

        touchpad = {
            natural_scroll          = i.touchpad.natural_scroll,
            scroll_factor           = i.touchpad.scroll_factor,
            tap_to_click            = i.touchpad.tap_to_click,
            disable_while_typing    = i.touchpad.disable_typing,
            clickfinger_behavior    = i.touchpad.clickfinger,
            middle_button_emulation = true,
        },
    },

    gestures = {
        workspace_swipe_distance           = 700,
        workspace_swipe_cancel_ratio       = 0.2,
        workspace_swipe_min_speed_to_force = 10,
        workspace_swipe_direction_lock     = true,
        workspace_swipe_create_new         = true,
    },
})

local g = vars.gestures
if g.workspace_fingers then
    hl.gesture({ fingers = g.workspace_fingers, direction = "horizontal", action = "workspace" })
end
if g.overview_fingers then
    -- Up: Reef's workspace overview (or nothing without the shell). Down: the scratchpad.
    hl.gesture({
        fingers   = g.overview_fingers,
        direction = "up",
        action    = function() hl.dispatch(hl.dsp.global("reef:overview")) end,
    })
    hl.gesture({ fingers = g.overview_fingers, direction = "down", action = "special", workspace_name = "scratchpad" })
end
