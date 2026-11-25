pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// The Tools tab's color picker: click a point on screen (slurp -p) and read that pixel
// (grim, as raw PPM: its last three bytes). The hex is copied; the last few picks are kept.
//
//   ColorPicker.pick()          // the Island closes first; `picked` follows
Singleton {
    id: root

    property bool busy: false
    property color current: "transparent"
    readonly property bool hasColor: current.a > 0
    // Most recent first.
    property var history: []

    signal picked(color c)

    function pick() {
        if (busy)
            return;
        busy = true;
        // Let the Island fold away first.
        delay.restart();
    }

    function hex(c) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `#${h(c.r)}${h(c.g)}${h(c.b)}`;
    }
    function rgb(c) {
        return `rgb(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)})`;
    }
    function hsl(c) {
        return `hsl(${Math.round(Math.max(0, c.hslHue) * 360)}, ${Math.round(c.hslSaturation * 100)}%, ${Math.round(c.hslLightness * 100)}%)`;
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    Timer {
        id: delay
        interval: Tokens.springs.spatialDefault.duration
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "p=$(slurp -p </dev/null) && grim -g \"$p\" -t ppm - | tail -c 3 | od -An -tx1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length !== 3)
                    return;
                const c = Qt.color("#" + parts.join(""));
                root.current = c;
                root.history = [c].concat(root.history.filter(h => !Qt.colorEqual(h, c))).slice(0, 8);
                root.copy(root.hex(c));
                root.picked(c);
            }
        }
        onExited: root.busy = false
    }
}
