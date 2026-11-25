pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.theme

// Which Tide panel and quick menu are open, and on which monitor.
//   panel: "" | "controlCenter" | "search" | "overview"
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

    // The workspace the overview has selected. The overview and the Navigator cay's
    // workspaces both show and move it, so they always agree.
    property int overviewWorkspace: 0
    // Go to a workspace through the open overview, as Enter on its card would (IPC).
    signal overviewGoRequested(int id)

    // ── holding Super ──
    // Holding Super for super-hold-delay shows the workspaces in the Navigator cay
    // (only there, not the overview). Letting go hides them, and since that release
    // is also a "tap Super" for search, search is skipped right after a hold.
    property bool superHeld: false
    property string superScreen: ""
    property real _skipSearchUntil: 0

    function superDown() {
        superScreen = _screen("");
        superHold.restart();
    }
    function superUp() {
        superHold.stop();
        if (superHeld)
            _skipSearchUntil = Date.now() + Tokens.superHoldDelay;
        superHeld = false;
    }
    property Timer _superHold: Timer {
        id: superHold
        interval: Tokens.superHoldDelay
        onTriggered: root.superHeld = true
    }

    readonly property var menus: ["calendar", "wifi", "bluetooth", "audio"]

    // The menu shown in the Status cay of `screen`, if any.
    function barMenu(screen) {
        return panel === "" && screenName === screen ? menu : "";
    }

    function _screen(screen) {
        return screen || Hyprland.focusedMonitor?.name || "";
    }

    function toggle(name, screen) {
        // The Super release that ends a hold isn't a tap.
        if (name === "search" && (superHeld || Date.now() < _skipSearchUntil))
            return;
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
