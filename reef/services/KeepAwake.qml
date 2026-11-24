pragma Singleton
import QtQuick
import Quickshell

// Keeps the screen from blanking or locking on idle, for a while or until turned off.
// The Wayland idle inhibitor itself lives on Reef's windows (Island, bar), which
// bind to `active`. The control center gets a tile for it in M3.
Singleton {
    id: root

    property bool active: false
    property real until: 0            // ms since epoch; 0 = until turned off
    property real now: Date.now()
    readonly property real remaining: until > 0 ? Math.max(0, (until - now) / 1000) : 0
    readonly property string text: until > 0 ? Countdown.format(remaining) : "On"

    // minutes <= 0 means until turned off
    function enable(minutes) {
        until = minutes > 0 ? Date.now() + minutes * 60000 : 0;
        now = Date.now();
        active = true;
    }

    function disable() {
        active = false;
        until = 0;
    }

    function toggle(minutes) {
        active ? disable() : enable(minutes ?? 0);
    }

    Timer {
        running: root.active && root.until > 0
        interval: 1000
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (root.now >= root.until)
                root.disable();
        }
    }
}
