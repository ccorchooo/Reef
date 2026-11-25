pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// CPU load, memory in use and GPU temperature, for the system home widget.
// It reads every stats-refresh, and only while something shows the numbers: a widget
// calls hold() when it appears and release() when it goes.
//   CPU: the busy share of /proc/stat's first line between two reads.
//   Memory: MemTotal - MemAvailable from /proc/meminfo.
//   GPU: nvidia-smi when installed, otherwise the first amdgpu/i915/xe/nouveau/radeon hwmon.
Singleton {
    id: root

    property int _users: 0
    readonly property bool active: _users > 0
    function hold() { _users++; }
    function release() { _users = Math.max(0, _users - 1); }

    property real cpu: 0               // 0..1
    property real memUsed: 0           // KiB
    property real memTotal: 0          // KiB
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    property real gpuTemp: -1          // °C; -1 = no sensor
    readonly property bool hasGpu: gpuTemp >= 0

    readonly property string cpuText: Math.round(cpu * 100) + "%"
    readonly property string memText: (memUsed / 1048576).toFixed(1) + " / " + Math.round(memTotal / 1048576) + "G"
    readonly property string gpuText: Math.round(gpuTemp) + "°C"

    property var _last: null

    function _parse(text) {
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const v = f.slice(1).map(Number);
                const idle = v[3] + (v[4] || 0);
                const total = v.reduce((a, b) => a + b, 0);
                if (_last && total > _last.total)
                    cpu = Math.max(0, Math.min(1, 1 - (idle - _last.idle) / (total - _last.total)));
                _last = { idle: idle, total: total };
            } else if (f[0] === "MemTotal:") {
                memTotal = Number(f[1]);
            } else if (f[0] === "MemAvailable:") {
                memUsed = memTotal - Number(f[1]);
            } else if (f[0] === "gpu") {
                const t = Number(f[1]);
                gpuTemp = f.length > 1 && !isNaN(t) ? t : -1;
            }
        }
    }

    Timer {
        running: root.active
        interval: Tokens.statsRefresh
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!reader.running) reader.running = true
    }

    Process {
        id: reader
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; "
            + "if command -v nvidia-smi >/dev/null 2>&1; then echo \"gpu $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)\"; "
            + "else for d in /sys/class/hwmon/hwmon*; do case $(cat $d/name 2>/dev/null) in amdgpu|i915|xe|nouveau|radeon) "
            + "echo \"gpu $(( $(cat $d/temp1_input) / 1000 ))\"; break;; esac; done; fi"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }
}
