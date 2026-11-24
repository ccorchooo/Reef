pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Region screenshot (grim + slurp): saved to Settings → Screenshots folder and copied
// to the clipboard, with a toast. The full Tools tab (M6) builds on this.
Singleton {
    id: root

    readonly property string folder: Config.options.screenshots.folder || (Quickshell.env("HOME") + "/Pictures/Screenshots")
    property bool busy: false

    signal taken(string path)

    // A short delay lets panels slide away first.
    function region() {
        if (busy)
            return;
        busy = true;
        delay.restart();
    }

    Timer {
        id: delay
        interval: Tokens.springs.spatialDefault.duration
        onTriggered: {
            const name = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".png";
            shot.path = root.folder + "/" + name;
            shot.running = true;
        }
    }

    // The path goes in argv, not the script.
    Process {
        id: shot
        property string path
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && g=$(slurp) && grim -g \"$g\" \"$1\" && wl-copy --type image/png < \"$1\"", "reef-screenshot", path]
        onExited: code => {
            root.busy = false;
            if (code === 0) {
                root.taken(path);
                Toasts.show({ text: "Screenshot copied", icon: "screenshot_region", action: "Open", onAction: () => Quickshell.execDetached(["xdg-open", shot.path]) });
            }
        }
    }
}
