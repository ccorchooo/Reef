pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Hyprland follows Reef's colors (Settings → Look → "Color Hyprland's borders").
// Reef's Hyprland config (hypr/config/modules/colors.lua) defines a Lua global,
// reef_apply_colors(mode, roles), that sets the window borders, shadows and groupbar.
// When the scheme or light/dark changes, Reef calls it through `hyprctl eval` once the
// crossfade has settled, so Hyprland recolors live with no config reload. With another
// Hyprland config the guard makes the call do nothing. At Hyprland start the config
// reads ~/.cache/reef/scheme.json itself.
Singleton {
    id: root

    readonly property bool enabled: Config.options.look.themeHyprland
    // The roles Hyprland uses (keep in step with colors.lua).
    readonly property var roles: ["primary", "secondary", "tertiary", "surface", "surfaceContainer", "surfaceContainerHigh", "outline", "outlineVariant", "onSurface", "onSurfaceVariant"]

    function apply() {
        if (!enabled)
            return;
        const pairs = roles.map(r => `${r} = "${String(Colors.role(r)).replace("#", "").slice(-6)}"`);
        const lua = `if reef_apply_colors then reef_apply_colors("${Colors.mode}", { ${pairs.join(", ")} }) end`;
        proc.command = ["hyprctl", "eval", lua];
        proc.running = true;
    }

    onEnabledChanged: if (enabled) settle.restart()
    Connections {
        target: Colors
        function on_TargetChanged() { settle.restart(); }
        function onModeChanged() { settle.restart(); }
    }
    // After the effects-slow crossfade, so Hyprland gets the colors Reef ends on.
    Timer {
        id: settle
        interval: Motion.duration(Motion.effectsSlow) * 2
        onTriggered: root.apply()
    }
    // Once at start: Reef's scheme may differ from the cache Hyprland read.
    Component.onCompleted: settle.restart()

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "ok" && text.trim() !== "") console.warn("CompositorTheme: hyprctl eval:", text.trim())
        }
    }
}
