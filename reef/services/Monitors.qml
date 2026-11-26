pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which monitor a surface should use (multi-monitor edge cases, M9).
//
//   Monitors.focused             // the focused monitor; the first one while Hyprland names none
//   Monitors.showing("bar", s)   // s (default: focused) if it shows the bar, else the first that does
//   Monitors.has(name)           // still connected?
//
// Hyprland's focused monitor is null until it connects (and briefly while outputs change),
// and can name an output Quickshell no longer lists; surfaces that live in the bar or the
// Island can be turned off per monitor (Settings → Displays). Asking here keeps a request
// from landing on a monitor that can't show it.
Singleton {
    id: root

    readonly property var names: Quickshell.screens.map(s => s.name)
    readonly property string focused: {
        const f = Hyprland.focusedMonitor?.name ?? "";
        return names.includes(f) ? f : (names[0] ?? "");
    }

    function has(name) {
        return name !== "" && names.includes(name);
    }

    // `what`: "bar" or "island". "" when no monitor shows it.
    function showing(what, name) {
        const key = what === "bar" ? "showBar" : "showIsland";
        const first = name || focused;
        if (has(first) && Config.monitor(first)[key])
            return first;
        return names.find(n => Config.monitor(n)[key]) ?? "";
    }
}
