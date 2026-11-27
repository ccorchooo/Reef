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

    readonly property string folder: Config.options.recordings.folder || (Quickshell.env("HOME") + "/Videos/Recordings")

    // Start recording, or stop the one running. mode: screen (the focused monitor),
    // sound (the same with the speakers' audio) or region (chosen with slurp).
    // gpu-screen-recorder, else wf-recorder. Detached, so a shell restart keeps it going;
    // the probe below picks it up as the recording activity either way.
    function toggle(mode) {
        if (active) {
            stop();
            return;
        }
        const name = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".mp4";
        const script = `out="$1"; mon="$2"; mode="$3"; fps="$4"; mkdir -p "$(dirname "$out")" || exit 1
if command -v gpu-screen-recorder >/dev/null; then
    set -- -f "$fps" -o "$out"
    [ "$mode" = sound ] && set -- "$@" -a default_output
    if [ "$mode" = region ]; then g=$(slurp -f '%wx%h+%x+%y' </dev/null) || exit 0; set -- -w region -region "$g" "$@"
    else set -- -w "$mon" "$@"; fi
    exec gpu-screen-recorder "$@"
elif command -v wf-recorder >/dev/null; then
    set -- -r "$fps" -f "$out"
    [ "$mode" = sound ] && set -- "$@" --audio
    if [ "$mode" = region ]; then g=$(slurp </dev/null) || exit 0; set -- -g "$g" "$@"
    else set -- -o "$mon" "$@"; fi
    exec wf-recorder "$@"
fi
notify-send -a Reef "Screen recording" "Install gpu-screen-recorder or wf-recorder to record." 2>/dev/null`;
        Quickshell.execDetached(["sh", "-c", script, "reef-record", folder + "/" + name, Monitors.focused, mode || "screen", String(Config.options.recordings.fps)]);
        recheck.restart();
    }

    // Notice the new recorder quickly instead of on the next 2 s probe.
    Timer {
        id: recheck
        interval: 600
        onTriggered: if (!probe.running) probe.running = true
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
