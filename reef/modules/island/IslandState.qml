pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Which Island is expanded (one at a time, on the monitor it was opened on),
// which tab it shows, and the current live activity.
Singleton {
    id: root

    property bool expanded: false
    property string screenName: ""
    property string tab: "now"

    // Live activities in priority order (recording, timer, playing media).
    readonly property var activities: [
        Recording.active ? "recording" : "",
        Countdown.active ? "timer" : "",
        Media.playing ? "media" : ""
    ].filter(a => a !== "")

    // The one the user put on the main Island by swapping; forgotten when it ends.
    property string preferred: ""

    // Shown on the main Island: the preferred one if it's live, else the highest priority.
    readonly property string activity: activities.includes(preferred) ? preferred : (activities[0] ?? "")
    // Shown in the pill below it: the next one in priority order.
    readonly property string secondaryActivity: activities.find(a => a !== activity) ?? ""

    // Put the secondary activity on the main Island.
    function swap() {
        if (secondaryActivity !== "")
            preferred = secondaryActivity;
    }

    readonly property var tabs: [
        { id: "now", icon: "graphic_eq", label: "Now" },
        { id: "shelf", icon: "inventory_2", label: "Shelf" },
        { id: "clipboard", icon: "content_paste", label: "Clipboard" },
        { id: "tools", icon: "widgets", label: "Tools" },
        { id: "coral", icon: "", label: "Coral" }
    ]
    // Tabs that exist so far; the others run their (stub) action.
    readonly property var builtTabs: ["now"]

    function open(tab, screen) {
        if (tab && !builtTabs.includes(tab)) {
            Actions.run(tab);
            return;
        }
        root.tab = tab || "now";
        screenName = screen || Hyprland.focusedMonitor?.name || "";
        expanded = true;
    }

    function close() {
        expanded = false;
    }

    function toggle(screen) {
        if (expanded)
            close();
        else
            open("now", screen);
    }

    Connections {
        target: Actions
        function onIslandRequested(tab) {
            root.expanded ? root.close() : root.open(tab);
        }
        function onIslandSwapRequested() {
            root.swap();
        }
    }
}
