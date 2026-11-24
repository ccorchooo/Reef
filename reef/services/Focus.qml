pragma Singleton
import QtQuick
import Quickshell

// Focus sessions: a focus period with Do not disturb on, then an optional break.
// Lengths are Settings → Notifications → Focus session.
Singleton {
    id: root

    property bool active: false
    property string phase: "focus"         // "focus" | "break"
    property bool paused: false
    property real total: 0
    property real remaining: 0
    property int completed: 0              // focus periods finished today
    readonly property string text: Countdown.format(remaining)

    property real _deadline: 0
    property bool _dndBefore: false

    signal phaseEnded(string phase)

    function start(minutes) {
        const m = minutes > 0 ? minutes : Config.options.focus.focusMinutes;
        if (!active)
            _dndBefore = Notifications.dnd;
        phase = "focus";
        _begin(m * 60);
        Notifications.setDnd(true);
    }

    function startBreak() {
        phase = "break";
        _begin(Config.options.focus.breakMinutes * 60);
        Notifications.setDnd(_dndBefore);
    }

    function stop() {
        if (active && phase === "focus")
            Notifications.setDnd(_dndBefore);
        active = false;
        paused = false;
    }

    function toggle() {
        if (!active)
            return;
        if (paused) {
            _deadline = Date.now() + remaining * 1000;
            paused = false;
        } else {
            _tick();
            paused = true;
        }
    }

    function _begin(seconds) {
        total = seconds;
        remaining = seconds;
        _deadline = Date.now() + seconds * 1000;
        paused = false;
        active = true;
    }

    function _tick() {
        remaining = Math.max(0, (_deadline - Date.now()) / 1000);
        if (remaining <= 0) {
            const ended = phase;
            if (ended === "focus") {
                completed++;
                Notifications.setDnd(_dndBefore);
            }
            active = false;
            phaseEnded(ended);
        }
    }

    Timer {
        running: root.active && !root.paused
        interval: 250
        repeat: true
        onTriggered: root._tick()
    }
}
