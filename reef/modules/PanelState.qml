pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Which Tide panel and quick menu are open, and on which monitor.
//   panel: "" | "controlCenter"
//   menu:  "" | "calendar" | "wifi" | "bluetooth" | "audio"
// A quick menu has two homes (SURFACES.md → Quick menus):
//   - with the control center open, it floats inside it. This is the default: opening
//     a menu from anywhere (a tile, the Island, a keybind, IPC) opens the control center.
//   - with no panel open, the Status cay grows into it (hovering a Status item).
Singleton {
    id: root

    property string panel: ""
    property string menu: ""
    property string screenName: ""

    readonly property var menus: ["calendar", "wifi", "bluetooth", "audio"]

    // The menu shown in the Status cay of `screen`, if any.
    function barMenu(screen) {
        return panel === "" && screenName === screen ? menu : "";
    }

    function _screen(screen) {
        return screen || Hyprland.focusedMonitor?.name || "";
    }

    function toggle(name, screen) {
        const s = _screen(screen);
        if (menus.includes(name)) {
            if (panel === "controlCenter" && menu === name && screenName === s)
                closeAll();
            else
                open(name, s);
            return;
        }
        const wasOpen = panel === name && screenName === s;
        menu = "";
        panel = wasOpen ? "" : name;
        screenName = s;
    }

    function open(name, screen) {
        const s = _screen(screen);
        if (menus.includes(name)) {
            if (screenName !== s)
                panel = "";
            screenName = s;
            panel = "controlCenter";
            menu = name;
        } else {
            menu = "";
            screenName = s;
            panel = name;
        }
    }

    // The Status cay's own menu (no panel).
    function openBarMenu(name, screen) {
        panel = "";
        screenName = screen;
        menu = name;
    }

    function toggleBarMenu(name, screen) {
        if (barMenu(screen) === name)
            closeAll();
        else
            openBarMenu(name, screen);
    }

    function closeMenu() {
        menu = "";
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
