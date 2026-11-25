pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output device (Pipewire).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!sink && sink.ready
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string icon: !ready ? "volume_off"
        : muted ? "volume_off"
        : volume <= 0.001 ? "volume_mute"
        : volume < 0.5 ? "volume_down" : "volume_up"

    readonly property string label: !ready ? "No audio output"
        : muted ? "Muted" : `Volume ${Math.round(volume * 100)}%`

    // Outputs (sinks) and the microphone: the default source, or, when the session has
    // none set (WirePlumber leaves it empty until one is chosen), the first input device.
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property PwNode source: Pipewire.defaultAudioSource ?? inputs[0] ?? null
    readonly property bool micMuted: source?.audio?.muted ?? false

    function outputName(node) {
        return node?.description || node?.nickname || node?.name || "Output";
    }

    function setOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function toggleMicMute() {
        if (source?.ready)
            source.audio.muted = !source.audio.muted;
    }

    function setVolume(v) {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => !!n)
    }
}
