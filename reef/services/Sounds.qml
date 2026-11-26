pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reef's UI sounds (DESIGN.md § 8): very subtle, short and soft, with a master toggle,
// a volume and one toggle per category (Settings → Sound). Never on hover.
// The files are assets/sounds/<name>.wav, synthesized from tokens.json by
// scripts/gen-sounds.py, and played with pw-play (or paplay) in the background.
//
//   Sounds.play("shelf")
Singleton {
    id: root

    readonly property var options: Config.options.sounds
    // Sound name → its Config toggle (sounds.<category>).
    readonly property var categories: ({
        lock: "lock", unlock: "lock", power: "power", island: "island", shelf: "shelf",
        listen: "coralListen", reply: "coralReply", notification: "notification"
    })
    // "pw-play", "paplay", or "" (none found: sounds stay quiet).
    property string player: ""
    property bool _checked: false
    // Asked for before the player check finished (the service starts on first use).
    property string _pending: ""
    property var _last: ({})

    function play(name) {
        const category = categories[name];
        if (!category || !options.enabled || !options[category])
            return;
        if (!_checked) {
            _pending = name;
            return;
        }
        if (player === "")
            return;
        // The same sound twice within a moment (two monitors reacting) plays once.
        const now = Date.now();
        if (now - (_last[name] ?? 0) < 80)
            return;
        _last[name] = now;
        const file = Quickshell.shellPath(`assets/sounds/${name}.wav`);
        const v = Math.max(0, Math.min(1, options.volume));
        if (player === "pw-play")
            Quickshell.execDetached(["pw-play", "--media-role", "Notification", "--volume", v.toFixed(2), file]);
        else
            Quickshell.execDetached(["paplay", `--volume=${Math.round(v * 65536)}`, file]);
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v pw-play >/dev/null && echo pw-play || { command -v paplay >/dev/null && echo paplay; }"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.player = text.trim();
                root._checked = true;
                if (root._pending !== "")
                    root.play(root._pending);
                root._pending = "";
            }
        }
    }
}
