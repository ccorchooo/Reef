pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player the shell shows (Spotlight cay, the Island).
// Prefers a playing player, then the last one that played.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var _lastPlaying: null
    readonly property var player: players.find(p => p.isPlaying) ?? (players.includes(_lastPlaying) ? _lastPlaying : players[0] ?? null)

    readonly property bool active: !!player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || player?.identity || ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    // Seconds. MPRIS doesn't push position updates, so it's re-read while playing.
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    readonly property bool canSeek: player?.canSeek ?? false
    readonly property bool canGoNext: player?.canGoNext ?? false
    readonly property bool canGoPrevious: player?.canGoPrevious ?? false
    readonly property bool shuffle: player?.shuffle ?? false
    readonly property bool shuffleSupported: player?.shuffleSupported ?? false
    readonly property bool loopSupported: player?.loopSupported ?? false
    readonly property int loopState: player?.loopState ?? MprisLoopState.None

    function togglePlaying() {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (canGoNext)
            player.next();
    }
    function previous() {
        if (canGoPrevious)
            player.previous();
    }
    function seekTo(fraction) {
        if (canSeek && length > 0)
            player.position = Math.max(0, Math.min(1, fraction)) * length;
    }
    function toggleShuffle() {
        if (shuffleSupported)
            player.shuffle = !player.shuffle;
    }
    function cycleLoop() {
        if (!loopSupported)
            return;
        player.loopState = loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    // "1:24"
    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? `${h}:${pad(m)}:${pad(r)}` : `${m}:${pad(r)}`;
    }

    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Variants {
        model: root.players
        Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying)
                    root._lastPlaying = modelData;
            }
        }
    }
}
