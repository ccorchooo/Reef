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

    function setVolume(v) {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
