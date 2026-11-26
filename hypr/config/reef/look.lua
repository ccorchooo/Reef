-- How windows look and behave: Reef's rhythm (gaps space-2 / space-4, corners
-- radius-lg, so windows nest with the cays), blur, shadows, layouts and groups.
-- Colors are in colors.lua.
local vars = require("reef.vars")
local t    = require("reef.tokens")
local look = vars.look

hl.config({
    general = {
        layout           = vars.layout,
        gaps_in          = look.gaps_in or t.gaps_in,
        gaps_out         = look.gaps_out or t.gaps_out,
        gaps_workspaces  = look.gaps_workspaces,
        border_size      = look.border_size,
        resize_on_border = true,
        extend_border_grab_area = 12,
        hover_icon_on_border    = true,
        allow_tearing    = true,          -- only for windows the `immediate` rule allows (games)
        snap = {
            enabled      = true,
            window_gap   = t["space-2"],
            monitor_gap  = t["space-4"],
            respect_gaps = true,
        },
    },

    decoration = {
        rounding         = look.rounding or t.rounding,
        rounding_power   = look.rounding_power,
        active_opacity   = look.active_opacity,
        inactive_opacity = look.inactive_opacity,
        dim_inactive     = look.dim_inactive,
        dim_strength     = look.dim_strength,
        dim_special      = 0.25,
        blur = {
            enabled           = look.blur.enabled,
            size              = look.blur.size,
            passes            = look.blur.passes,
            vibrancy          = look.blur.vibrancy,
            popups            = look.blur.popups,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            special           = false,
        },
        shadow = {
            enabled      = look.shadow.enabled,
            range        = look.shadow.range,
            render_power = look.shadow.power,
            offset       = { 0, 4 },
        },
    },

    dwindle = {
        preserve_split  = true,
        smart_resizing  = true,
        force_split     = 2,              -- new windows open to the right / below
    },
    master = {
        new_status     = "slave",
        mfact          = 0.55,
        smart_resizing = true,
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.5,
        explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",
        focus_fit_method         = 1,
    },

    group = {
        auto_group = true,
        groupbar   = {
            enabled       = true,
            font_family   = look.font,
            font_size     = 11,
            height        = 18,
            indicator_height = 0,
            rounding      = t["radius-sm"],
            gradients     = true,
            gradient_rounding = t["radius-sm"],
            gaps_in       = t["space-1"],
            gaps_out      = t["space-1"],
            keep_upper_gap = false,
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        vrr                      = 2,     -- adaptive sync for fullscreen apps only
        focus_on_activate        = true,
        animate_manual_resizes   = true,
        animate_mouse_windowdragging = false,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        -- Reef's lock screen can come back after the shell restarts.
        allow_session_lock_restore = true,
        middle_click_paste       = false,
        new_float_force_onscreen = 1,
        enable_anr_dialog        = true,
    },

    binds = {
        workspace_back_and_forth = true,  -- the current workspace's key goes back
        allow_workspace_cycles   = true,
        movefocus_cycles_fullscreen = false,
        drag_threshold           = 10,
    },

    cursor = {
        hide_on_key_press  = true,
        warp_on_change_workspace = 1,
        no_warps           = false,
        inactive_timeout   = 0,
    },

    xwayland = {
        force_zero_scaling = true,        -- crisp X11 apps on scaled monitors
    },

    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})
