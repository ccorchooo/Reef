pragma Singleton
import QtQuick
import Quickshell

// One countdown timer: the Island's timer activity. Started from IPC now
// (`qs -p ./reef ipc call reef timer 5m`) and from the Tools tab in M6.
Singleton {
    id: root

    property bool active: false
    property bool paused: false
    property real total: 0          // seconds
    property real remaining: 0      // seconds
    property string label: "Timer"
    readonly property real progress: total > 0 ? 1 - remaining / total : 0
    readonly property string text: format(remaining)

    signal finished

    property real _deadline: 0

    function start(seconds, name) {
        if (!(seconds > 0))
            return;
        total = seconds;
        remaining = seconds;
        label = name || "Timer";
        _deadline = Date.now() + seconds * 1000;
        paused = false;
        active = true;
    }

    function pause() {
        if (active && !paused) {
            _tick();
            paused = true;
        }
    }

    function resume() {
        if (active && paused) {
            _deadline = Date.now() + remaining * 1000;
            paused = false;
        }
    }

    function toggle() {
        paused ? resume() : pause();
    }

    function cancel() {
        active = false;
        paused = false;
        remaining = 0;
    }

    // "5m", "90s", "1h30m", "4:12", "300" → seconds (0 if unreadable)
    function parse(input) {
        const s = String(input).trim().toLowerCase();
        if (/^\d+(:\d{1,2}){1,2}$/.test(s))
            return s.split(":").reduce((acc, p) => acc * 60 + Number(p), 0);
        if (/^\d+(\.\d+)?$/.test(s))
            return Number(s);
        // (QML's JS engine has no String.matchAll)
        const re = /(\d+(?:\.\d+)?)\s*(h|m|s)/g;
        let total = 0, matched = false, m;
        while ((m = re.exec(s)) !== null) {
            total += Number(m[1]) * ({ h: 3600, m: 60, s: 1 })[m[2]];
            matched = true;
        }
        return matched ? total : 0;
    }

    function format(seconds) {
        const s = Math.max(0, Math.ceil(seconds));
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? `${h}:${pad(m)}:${pad(r)}` : `${pad(m)}:${pad(r)}`;
    }

    function _tick() {
        remaining = Math.max(0, (_deadline - Date.now()) / 1000);
        if (remaining <= 0) {
            active = false;
            finished();
        }
    }

    Timer {
        running: root.active && !root.paused
        interval: 200
        repeat: true
        onTriggered: root._tick()
    }
}
