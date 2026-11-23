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

    // Highest-priority live activity: "recording", "timer", "media" or "" (DESIGN.md: the Island).
    readonly property string activity: Recording.active ? "recording"
        : Countdown.active ? "timer"
        : Media.playing ? "media" : ""

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
    }
}
