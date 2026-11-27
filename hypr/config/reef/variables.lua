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
        terminal = lib.which({ "kitty", "foot", "ghostty", "alacritty", "wezterm", "konsole", "gnome-terminal" }) or "kitty",
        browser  = lib.which({ "zen-browser", "firefox", "chromium", "brave", "google-chrome-stable" }) or "xdg-open https://",
        files    = lib.which({ "nautilus", "thunar", "dolphin", "nemo", "pcmanfm-qt", "pcmanfm" }) or "xdg-open " .. lib.home,
        editor   = lib.which({ "codium", "code", "zeditor", "gnome-text-editor", "kate", "mousepad" }),
        audio    = lib.which({ "pwvucontrol", "pavucontrol" }),
        picker   = lib.which({ "hyprpicker -a" }),
        -- The system monitor on Ctrl+Shift+Escape, in its own special workspace.
        monitor  = lib.which({ "btop", "htop" }),
    },

    -- The main modifier for the workspace number keys (Reef's keys are in reef.lua).
    mod = "SUPER",

    -- This config's keys (Caelestia's layout). Each is one key or a list; set one to
    -- false to free it, e.g. keys = { browser = false } or { terminal = "SUPER + T" }.
    -- Reef's own keys (search, Island, Coral, panels, lock, media…) are reef.lua's;
    -- change those with shellKeys below. `reef doctor` checks that no two collide.
    keys = {
        terminal       = { "SUPER + Return", "SUPER + T" },
        browser        = "SUPER + W",
        editor         = "SUPER + C",
        files          = "SUPER + E",
        audio          = "CTRL + ALT + V",
        picker         = "SUPER + SHIFT + C",
        sysmon         = "CTRL + SHIFT + Escape",

        close          = "SUPER + Q",
        kill           = "SUPER + SHIFT + Q",
        fullscreen     = "SUPER + F",
        maximize       = "SUPER + ALT + F",
        float          = { "SUPER + ALT + Space", "SUPER + SHIFT + F" },
        pin            = "SUPER + P",
        pip            = "SUPER + ALT + backslash",
        center         = "CTRL + SUPER + backslash",
        normalize      = "CTRL + SUPER + ALT + backslash",
        togglesplit    = "SUPER + J",
        nextLayout     = "SUPER + backslash",
        resizeMode     = "SUPER + SHIFT + R",
        dragKey        = "SUPER + Z",        -- hold and move the mouse
        resizeKey      = "SUPER + X",
        narrower       = { "SUPER + minus", "SUPER + ALT + left" },
        wider          = { "SUPER + equal", "SUPER + ALT + right" },
        shorter        = { "SUPER + SHIFT + minus", "SUPER + ALT + up" },
        taller         = { "SUPER + SHIFT + equal", "SUPER + ALT + down" },

        groupToggle    = { "SUPER + comma", "SUPER + G" },
        groupLock      = "SUPER + SHIFT + comma",
        ungroup        = "SUPER + U",
        groupNext      = { "CTRL + ALT + Tab", "SUPER + bracketright" },
        groupPrev      = { "CTRL + SHIFT + ALT + Tab", "SUPER + bracketleft" },

        -- Workspaces: mod + 1…0 go there; these are the modifiers for the rest.
        moveToWs       = "SUPER + ALT",      -- + 1…0: take the window along
        moveToWsSilent = "SUPER + SHIFT",    -- + 1…0: send it, stay here
        wsGroup        = "CTRL + SUPER",     -- + 1…0: the same slot in group 1…10
        moveToWsGroup  = "CTRL + SUPER + ALT",
        nextWs         = { "SUPER + mouse_down", "CTRL + SUPER + right", "SUPER + Page_Down" },
        prevWs         = { "SUPER + mouse_up", "CTRL + SUPER + left", "SUPER + Page_Up" },
        nextWsGroup    = "CTRL + SUPER + mouse_down",
        prevWsGroup    = "CTRL + SUPER + mouse_up",
        moveToNextWs   = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + right" },
        moveToPrevWs   = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + left" },
        scratchpad     = "SUPER + S",
        toScratchpad   = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + up" },
        fromSpecial    = "CTRL + SUPER + SHIFT + down",
        nextMonitor    = "SUPER + O",
        windowToMonitor = "SUPER + SHIFT + O",

        restartShell   = { "CTRL + SUPER + R", "CTRL + SUPER + ALT + R" },
        killShell      = "CTRL + SUPER + SHIFT + R",
        restoreLock    = "SUPER + ALT + L",
        pasteLatest    = "CTRL + SHIFT + ALT + V",
        testNotification = "SUPER + ALT + F12",
    },

    -- Reef's own keys (reef.lua), by action: { coral = "SUPER + Y" } moves one,
    -- { coral = false } frees it. See reef.lua for the list.
    shellKeys = {},

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

    -- Apps that open in their own special workspace, shown with its key (Caelestia's).
    -- `exec` starts when the workspace is shown empty.
    specials = {
        music  = { key = "SUPER + M", classes = { "Spotify", "spotify", "feishin", "Cider", "com.github.th-ch.youtube-music" }, titles = { "Spotify", "Spotify Free" } },
        chat   = { key = "SUPER + D", classes = { "discord", "vesktop", "equibop", "legcord", "WebCord", "org.telegram.desktop", "whatsapp" }, titles = {} },
        todo   = { key = "SUPER + R", classes = { "todoist", "Todoist", "io.github.alainm23.planify", "org.gnome.Todo" }, titles = {} },
        sysmon = { classes = { "reef-sysmon" }, titles = {} },
    },

    -- More commands to start with Hyprland.
    autostart = {},
}
