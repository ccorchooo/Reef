pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Which Tide panel or quick menu is open, and on which monitor. One at a time:
// opening one closes the others.
//   panel: "" | "controlCenter"
//   menu:  "" | "calendar" | "wifi" | "bluetooth" | "audio"
Singleton {
    id: root

    property string panel: ""
    property string menu: ""
    property string screenName: ""

    function _screen(screen) {
        return screen || Hyprland.focusedMonitor?.name || "";
    }

    function toggle(name, screen) {
        const s = _screen(screen);
        const isMenu = ["calendar", "wifi", "bluetooth", "audio"].includes(name);
        const open = (isMenu ? menu : panel) === name && screenName === s;
        panel = "";
        menu = "";
        if (!open) {
            screenName = s;
            if (isMenu)
                menu = name;
            else
                panel = name;
        }
    }

    function open(name, screen) {
        if ((panel === name || menu === name) && screenName === _screen(screen))
            return;
        toggle(name, screen);
    }

    function closeAll() {
        panel = "";
        menu = "";
    }

    Connections {
        target: Actions
        function onPanelRequested(name) { root.toggle(name); }
    }
}
