pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The active keyboard layout, for the lock screen and greeter ("EN").
// Read from `hyprctl devices -j` (the main keyboard) and kept current with Hyprland's
// activelayout event.
Singleton {
    id: root

    // Hyprland's name for it: "English (US)".
    property string layout: ""
    // Two capitals: "EN".
    readonly property string short: layout === "" ? "" : layout.replace(/[^A-Za-z]/g, "").slice(0, 2).toUpperCase()

    function refresh() {
        devices.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: devices
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards ?? [];
                    const kb = kbs.find(k => k.main) ?? kbs[0];
                    if (kb)
                        root.layout = kb.active_keymap ?? "";
                } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;
            // "keyboard-name,Layout name"
            const data = event.data;
            root.layout = data.slice(data.indexOf(",") + 1);
        }
    }
}
