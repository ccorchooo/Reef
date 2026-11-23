pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Named shell actions, shared by keybinds (modules/Commands), IPC and buttons.
// Built actions run their handler; the rest log which milestone builds them.
Singleton {
    id: root

    // name → [description, milestone]   (keybinds: SURFACES.md → Keybinds)
    readonly property var actions: ({
            home: ["Home", "M4"],
            search: ["Open search", "M4"],
            island: ["Open the Island", "M2"],
            clipboard: ["Island → Clipboard", "M6"],
            shelf: ["Island → Shelf", "M6"],
            tools: ["Island → Tools", "M6"],
            emoji: ["Island → Tools (emoji)", "M6"],
            coral: ["Coral voice", "M8"],
            controlCenter: ["Control and notification center", "M3"],
            calendar: ["Calendar", "M3"],
            audioOutput: ["Audio output menu", "M3"],
            overview: ["Workspace overview", "M4"],
            switcher: ["Window switcher", "M4"],
            editMode: ["Edit mode", "M7"],
            lock: ["Lock", "M5"],
            power: ["Power actions", "M5"],
            focusBar: ["Keyboard focus to the bar", "M1"],
            volumeUp: ["Volume up", "M2"],
            volumeDown: ["Volume down", "M2"],
            volumeMute: ["Mute", "M2"],
            brightnessUp: ["Brightness up", "M2"],
            brightnessDown: ["Brightness down", "M2"]
        })

    // Actions with a global shortcut (bound in hypr/reef.lua).
    readonly property var shortcuts: ["search", "island", "clipboard", "emoji", "coral", "controlCenter", "overview", "switcher", "editMode", "lock", "power", "focusBar", "volumeUp", "volumeDown", "volumeMute", "brightnessUp", "brightnessDown"]

    // Surfaces listen to these.
    signal focusBarRequested
    signal islandRequested(string tab)

    readonly property var handlers: ({
            focusBar: () => root.focusBarRequested(),
            island: () => root.islandRequested("now"),
            volumeUp: () => Audio.setVolume(Audio.volume + 0.05),
            volumeDown: () => Audio.setVolume(Audio.volume - 0.05),
            volumeMute: () => Audio.toggleMute(),
            brightnessUp: () => Brightness.step(0.05),
            brightnessDown: () => Brightness.step(-0.05)
        })

    function run(name) {
        const handler = handlers[name];
        if (handler) {
            handler();
            return;
        }
        const a = actions[name];
        if (!a) {
            console.warn("Reef: unknown action", name);
            return;
        }
        console.info("Reef:", a[0], "isn't built yet (" + a[1] + ")");
    }
}
