-- Every setting this config reads, with its default. Don't edit this file: put the
-- ones you want to change in user/variables.lua (tables merge key by key there, so
-- `{ input = { layout = "de" } }` changes only the layout).
local lib = require("reef.lib")

return {
    -- Reef's shell. false: plain Hyprland without the shell (no start, no Reef keys).
    shell    = true,
    -- Where Reef's hypr folder is, if not in the usual places (see lib.load_shell).
    reefHypr = nil,

    -- Apps, the first one installed of each list.
    apps = {
        terminal = lib.which({ "foot", "kitty", "ghostty", "alacritty", "wezterm", "konsole", "gnome-terminal" }) or "foot",
        browser  = lib.which({ "zen-browser", "firefox", "chromium", "brave", "google-chrome-stable" }) or "xdg-open https://",
        files    = lib.which({ "nautilus", "thunar", "dolphin", "nemo", "pcmanfm-qt", "pcmanfm" }) or "xdg-open " .. lib.home,
        editor   = lib.which({ "code", "codium", "zeditor", "gnome-text-editor", "kate", "mousepad" }),
        picker   = lib.which({ "hyprpicker -a" }),
    },

    -- The main modifier for this config's own binds (Reef's keys are in reef.lua).
    mod = "SUPER",

    input = {
        layout       = "us",
        variant      = "",
        options      = "",            -- e.g. "grp:alt_shift_toggle,caps:escape"
        repeat_rate  = 35,
        repeat_delay = 250,
        sensitivity  = 0,             -- -1 … 1
        accel        = "",            -- "" (libinput's default), "flat" or "adaptive"
        follow_mouse = 1,
        numlock      = true,
        touchpad = {
            natural_scroll    = true,
            scroll_factor     = 0.4,
            tap_to_click      = true,
            disable_typing    = true,
            clickfinger       = true, -- two-finger click = right click
        },
    },

    gestures = {
        workspace_fingers = 3,        -- swipe sideways: workspaces
        overview_fingers  = 4,        -- swipe up: Reef's overview; down: the scratchpad
    },

    look = {
        -- nil = Reef's tokens (gaps space-2 / space-4, corners radius-lg).
        gaps_in        = nil,
        gaps_out       = nil,
        gaps_workspaces = 32,         -- between workspaces while they slide
        rounding       = nil,
        rounding_power = 2,           -- 2 = circular corners, higher = squircle
        border_size    = 2,
        -- Opacity of windows; terminals and the like look best a touch see-through.
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive   = false,
        dim_strength   = 0.08,
        blur = {
            enabled = true,
            size    = 6,
            passes  = 3,
            vibrancy = 0.17,
            popups  = true,
        },
        shadow = {
            enabled = true,
            range   = 20,
            power   = 3,
            -- Reef's shadow-menu: black at 0.45 (dark) / 0.2 (light).
            alpha_dark  = "73",
            alpha_light = "33",
        },
        -- Inactive border: the outline at this alpha (hex). Active: the primary.
        inactive_border_alpha = "55",
        font = "sans-serif",          -- the groupbar's titles
    },

    -- dwindle | master | scrolling (SUPER + backslash cycles them)
    layout = "dwindle",

    animations = {
        enabled = true,
        -- Window open/close style: "popin 90%", "slide", "gnomed"…
        window_style = "popin 90%",
        workspace_style = "slide",
    },

    -- Extra hl.monitor specs, e.g. { output = "DP-1", mode = "2560x1440@165", position = "auto-right", scale = 1 }
    monitors = {},

    cursor = {
        theme = nil,                  -- e.g. "Bibata-Modern-Classic"; nil = leave it alone
        size  = 24,
    },

    -- NVIDIA environment variables: "auto" (when the driver is loaded), true or false.
    nvidia = "auto",

    -- Apps that open in their own special workspace (shown with a key, see binds.lua).
    specials = {
        music = { key = "M", classes = { "Spotify", "spotify", "feishin", "Cider", "com.github.th-ch.youtube-music" }, titles = { "Spotify", "Spotify Free" } },
        chat  = { key = "D", classes = { "discord", "vesktop", "equibop", "WebCord", "org.telegram.desktop", "whatsapp" }, titles = {} },
    },

    -- More commands to start with Hyprland.
    autostart = {},
}
