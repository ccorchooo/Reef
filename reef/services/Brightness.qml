pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight through brightnessctl. `available` is false without a backlight
// (most desktops with external monitors).
Singleton {
    id: root

    property bool available: false
    property real level: 0          // 0..1
    signal changedByUser

    function set(v) {
        if (!available)
            return;
        level = Math.max(0.01, Math.min(1, v));
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(level * 100) + "%"]);
        changedByUser();
    }

    function step(delta) {
        set(level + delta);
    }

    // "intel_backlight,backlight,12000,50%,24000"
    Process {
        id: read
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5 && f[1] === "backlight") {
                    root.available = true;
                    root.level = Number(f[2]) / Number(f[4]);
                }
            }
        }
    }
}
