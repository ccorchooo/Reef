pragma Singleton
import QtQuick
import Quickshell

// A stopwatch with laps: the Island's stopwatch activity. Started from IPC now
// (`qs -p ./reef ipc call stopwatch start`) and from the Tools tab in M6.
Singleton {
    id: root

    property bool running: false
    readonly property bool active: running || elapsed > 0
    property real elapsed: 0          // seconds
    property var laps: []             // lap split times, seconds since start
    readonly property string text: format(elapsed)

    property real _startedAt: 0
    property real _base: 0

    function start() {
        if (running)
            return;
        _base = elapsed;
        _startedAt = Date.now();
        running = true;
    }

    function pause() {
        if (!running)
            return;
        _tick();
        running = false;
    }

    function toggle() {
        running ? pause() : start();
    }

    function lap() {
        if (running) {
            _tick();
            laps = laps.concat([elapsed]);
        }
    }

    function reset() {
        running = false;
        elapsed = 0;
        laps = [];
    }

    // "01:23.4" under an hour, "1:02:03" after
    function format(seconds) {
        const s = Math.max(0, seconds);
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        if (h > 0)
            return `${h}:${pad(m)}:${pad(Math.floor(r))}`;
        return `${pad(m)}:${pad(Math.floor(r))}.${Math.floor((r % 1) * 10)}`;
    }

    function _tick() {
        elapsed = _base + (Date.now() - _startedAt) / 1000;
    }

    Timer {
        running: root.running
        interval: 100
        repeat: true
        onTriggered: root._tick()
    }
}
