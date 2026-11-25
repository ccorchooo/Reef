pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

// Screenshots (grim + slurp): saved to Settings → Screenshots folder and copied to the
// clipboard, with a toast. Region (choose with slurp), the focused screen, or the active
// window. Used by the control center tile, the screenshot action and the Tools tab.
Singleton {
    id: root

    readonly property string folder: Config.options.screenshots.folder || (Quickshell.env("HOME") + "/Pictures/Screenshots")
    property bool busy: false

    signal taken(string path)

    function region() {
        take("region");
    }

    // mode: region | screen | window. A short delay lets panels slide away first.
    function take(mode) {
        if (busy)
            return;
        busy = true;
        shot.mode = mode;
        delay.restart();
    }

    Timer {
        id: delay
        interval: Tokens.springs.spatialDefault.duration
        onTriggered: {
            const name = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".png";
            shot.path = root.folder + "/" + name;
            // Where to capture: grim's -g geometry or -o output, worked out in the script.
            const geometry = {
                region: "g=$(slurp </dev/null) || exit 1; set -- -g \"$g\"",
                screen: "set -- -o \"$2\"",
                window: "g=$(hyprctl activewindow -j | sed -n 's/.*\"at\": \\[\\([0-9-]*\\), \\([0-9-]*\\)\\].*/\\1,\\2/p;' | head -1); "
                    + "s=$(hyprctl activewindow -j | tr -d '\\n ' | sed -n 's/.*\"size\":\\[\\([0-9]*\\),\\([0-9]*\\)\\].*/\\1x\\2/p'); "
                    + "[ -n \"$s\" ] || exit 1; set -- -g \"$g $s\""
            }[shot.mode];
            shot.command = ["sh", "-c",
                `out="$1"; mkdir -p "$(dirname "$out")" && { ${geometry}; } && grim "$@" "$out" && wl-copy --type image/png < "$out" >/dev/null 2>&1`,
                "reef-screenshot", shot.path, Hyprland.focusedMonitor?.name ?? ""];
            shot.running = true;
        }
    }

    // Paths and names go in argv, not the script. slurp reads preset boxes from stdin when
    // it isn't a terminal and waits for it to close, so it gets /dev/null; wl-copy stays
    // behind to serve the clipboard, so its output goes to /dev/null too, or the
    // Process would never see the script end.
    Process {
        id: shot
        property string path
        property string mode: "region"
        onExited: code => {
            root.busy = false;
            if (code === 0) {
                root.taken(path);
                Toasts.show({ text: "Screenshot copied", icon: "screenshot_region", action: "Open", onAction: () => Quickshell.execDetached(["xdg-open", shot.path]) });
            }
        }
    }
}
