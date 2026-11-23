pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording in progress, for the Island's recording activity.
// Detects gpu-screen-recorder, wf-recorder and wl-screenrec (whoever started them);
// Reef's own recorder arrives with the Tools tab (M6).
// Settings → Bar & Island → Detect screen recording turns the check off.
Singleton {
    id: root

    readonly property bool enabled: Config.options.island.detectRecording
    property bool active: false
    property int pid: 0
    property real startedAt: 0      // ms since epoch
    property real now: Date.now()
    readonly property real elapsed: active ? Math.max(0, (now - startedAt) / 1000) : 0
    readonly property string text: {
        const s = Math.floor(elapsed);
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? `${h}:${pad(m)}:${pad(r)}` : `${pad(m)}:${pad(r)}`;
    }

    // Ask the recorder to finish and save (SIGINT, like Ctrl+C).
    function stop() {
        if (active && pid > 0)
            Quickshell.execDetached(["kill", "-INT", String(pid)]);
    }

    // comm names are cut to 15 characters, hence "gpu-screen-reco".
    Process {
        id: probe
        command: ["sh", "-c", "p=$(pgrep -nx 'gpu-screen-reco|wf-recorder|wl-screenrec') && ps -o pid=,etimes= -p \"$p\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 2 && Number(parts[0]) > 0) {
                    const pid = Number(parts[0]);
                    if (!root.active || pid !== root.pid) {
                        root.pid = pid;
                        root.startedAt = Date.now() - Number(parts[1]) * 1000;
                    }
                    root.active = true;
                } else {
                    root.active = false;
                    root.pid = 0;
                }
            }
        }
    }

    Timer {
        running: root.enabled
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }

    Timer {
        running: root.active
        interval: 1000
        repeat: true
        onTriggered: root.now = Date.now()
    }

    onEnabledChanged: if (!enabled) active = false
}
