pragma Singleton
import QtQuick
import Quickshell

// The Settings app's state: whether its window is open and which page it shows.
// Opened with the `settings` action (`qs -p ./reef ipc call reef settings [page]`), the
// quick menus' settings buttons and search.
Singleton {
    id: root

    property bool open: false
    property string page: "look"
    property string query: ""

    readonly property var pages: [
        { id: "look", title: "Look", icon: "palette" },
        { id: "displays", title: "Displays", icon: "monitor" },
        { id: "bar", title: "Bar & Island", icon: "dock_to_bottom" },
        { id: "apps", title: "Apps", icon: "apps" },
        { id: "widgets", title: "Widgets", icon: "widgets" },
        { id: "sound", title: "Sound", icon: "volume_up" },
        { id: "network", title: "Network", icon: "wifi" },
        { id: "bluetooth", title: "Bluetooth", icon: "bluetooth" },
        { id: "coral", title: "Coral", icon: "graphic_eq" },
        { id: "keyboard", title: "Keyboard & shortcuts", icon: "keyboard" },
        { id: "power", title: "Power & performance", icon: "bolt" },
        { id: "accessibility", title: "Accessibility", icon: "accessibility_new" },
        { id: "about", title: "About", icon: "info" }
    ]

    // What each page holds, for "Search settings": [page, label, extra words].
    readonly property var index: [
        ["look", "Wallpaper", "background image picture"],
        ["look", "Seed color", "accent static color wallpaper colors"],
        ["look", "Palette", "gruvbox catppuccin nord tokyo night rose pine everforest solarized dracula theme scheme classic"],
        ["look", "Colorfulness", "mono neutral tinted vivid deep scheme"],
        ["look", "Theme", "dark light auto appearance"],
        ["look", "Transparency", "solid frosted blur"],
        ["look", "Home logo", "reef distro custom image"],
        ["look", "Draw the wallpaper", "background"],
        ["displays", "Bar on this monitor", "per monitor"],
        ["displays", "Island on this monitor", "per monitor"],
        ["displays", "Bar position", "left bottom"],
        ["displays", "Home widgets", "desktop clock weather"],
        ["displays", "Rounded screen corners", "corners"],
        ["displays", "Night light", "warm temperature blue light"],
        ["bar", "Show Spotlight cay", "media special widget"],
        ["bar", "Status menus on hover", "quick menus"],
        ["bar", "Cay order", "reorder rearrange move dock navigator status"],
        ["bar", "Workspaces in their own cay", "numbers workspace cay"],
        ["bar", "Bluetooth in the Status cay", "status bar"],
        ["bar", "Spotlight", "special widget media timer event weather system default"],
        ["bar", "Panels push the bar", "tide control center"],
        ["bar", "Workspaces", "navigator count"],
        ["bar", "Clock format", "24-hour 12-hour time"],
        ["bar", "Island peek", "hover"],
        ["bar", "Hide the Island over apps", "reveal"],
        ["bar", "Activities", "recording timer media battery bluetooth"],
        ["bar", "Edit home", "widgets edit mode"],
        ["bar", "Weather location", "city temperature unit"],
        ["bar", "Volume and brightness OSD", "overlay"],
        ["bar", "Toasts", "popups"],
        ["bar", "Do not disturb", "dnd notifications"],
        ["bar", "Clipboard history", "cliphist"],
        ["bar", "Search files", "find"],
        ["bar", "Focus session", "pomodoro break"],
        ["bar", "Calendars", "ics events"],
        ["apps", "Default apps", "browser terminal files editor mail images video music pdf open with"],
        ["apps", "Dock", "pinned apps pin unpin order"],
        ["apps", "Apps in search", "hide show hidden launcher"],
        ["widgets", "Clock", "analog face"],
        ["widgets", "Clock shape", "circle squircle cookie sunny flower clover"],
        ["widgets", "Clock numbers", "numerals hours quarters background"],
        ["widgets", "Second hand", "seconds"],
        ["widgets", "Hour ticks", "marks"],
        ["widgets", "Clock color", "face primary tertiary"],
        ["sound", "Volume", "audio"],
        ["sound", "Output", "speakers headphones"],
        ["sound", "Mute microphone", "mic input"],
        ["network", "Wi-Fi", "wireless internet networks"],
        ["bluetooth", "Bluetooth", "devices pair headphones"],
        ["coral", "Endpoint", "api openai url server"],
        ["coral", "Model", "llm"],
        ["coral", "Voice", "speech"],
        ["keyboard", "Shortcuts", "keybinds keys"],
        ["keyboard", "Keyboard layout", "language"],
        ["power", "Lock before sleep", "suspend"],
        ["power", "Authentication dialog", "polkit"],
        ["power", "Low battery", "battery level"],
        ["power", "Blur", "frosted performance"],
        ["power", "Shape morphs", "performance animation"],
        ["power", "Audio visualizer", "cava waveform"],
        ["power", "Live window thumbnails", "overview switcher"],
        ["accessibility", "Reduce motion", "animations"],
        ["accessibility", "Animation speed", "motion"],
        ["accessibility", "Zoom", "scale size bigger smaller whole shell"],
        ["accessibility", "Text size", "scale font"],
        ["accessibility", "Spacing", "scale density"],
        ["accessibility", "Corner roundness", "scale radius"],
        ["about", "About Reef", "version system"]
    ]

    function title(id) {
        return pages.find(p => p.id === id)?.title ?? "";
    }

    function show(id) {
        if (id && pages.some(p => p.id === id))
            page = id;
        query = "";
        open = true;
    }

    function close() {
        open = false;
        query = "";
    }
}
