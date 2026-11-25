pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history for the Island's Clipboard tab (SURFACES.md → The Island;
// parts/Island-Clipboard). The history is cliphist's (hypr/reef.lua starts
// `wl-paste --watch cliphist store`); Reef adds pins and when each entry was copied.
//
// Pins keep their text in $XDG_DATA_HOME/reef/clipboard.json, so they outlive the
// history. cliphist keeps no times: Reef notes when it first sees an entry (entries
// from before Reef ran have none).
//
//   Clipboard.query = "pacman"; Clipboard.results   // pins first, then the history
//   Clipboard.copy(entry)                            // back on the clipboard
Singleton {
    id: root

    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/reef"
    readonly property int limit: Math.max(1, Config.options.clipboard.limit)

    // [{ id, line, text, kind, pinned, seen }]; kind: text | code | color | path | image
    property var history: []
    property string query: ""
    readonly property var pins: (store.pins ?? []).map(p => _entry(null, p.text, true, p.at))
    readonly property var results: {
        const q = query.trim().toLowerCase();
        const pinned = new Set(pins.map(p => p.text));
        const all = pins.concat(history.filter(e => !pinned.has(e.text)));
        return q === "" ? all : all.filter(e => e.text.toLowerCase().includes(q) || e.label.toLowerCase().includes(q));
    }

    function refresh() {
        list.running = true;
    }

    function copy(entry) {
        if (entry.pinned || entry.id === null)
            Quickshell.execDetached(["wl-copy", "--", entry.text]);
        else
            Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "reef-clipboard", entry.id]);
    }

    function pin(entry) {
        if (entry.kind === "image" || isPinned(entry))
            return;
        store.pins = [{ text: entry.text, at: entry.seen ?? Date.now() }].concat(store.pins ?? []);
    }
    function unpin(entry) {
        store.pins = (store.pins ?? []).filter(p => p.text !== entry.text);
    }
    function isPinned(entry) {
        return (store.pins ?? []).some(p => p.text === entry.text);
    }

    function remove(entry) {
        if (entry.pinned) {
            unpin(entry);
            return;
        }
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "reef-clipboard", entry.line]);
        history = history.filter(e => e.id !== entry.id);
    }

    // "now", "2 min", "1 h", "3 d"; "" when unknown.
    function age(ms, now) {
        if (!ms)
            return "";
        const s = Math.max(0, (now - ms) / 1000);
        return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)} min` : s < 86400 ? `${Math.floor(s / 3600)} h` : `${Math.floor(s / 86400)} d`;
    }

    function _kind(text) {
        if (/^\[\[ binary data .* \]\]$/.test(text))
            return "image";
        const t = text.trim();
        if (/^(#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})|rgba?\([\d\s.,%]+\))$/i.test(t))
            return "color";
        if (/^(~|\/|file:\/\/)\S*$/.test(t))
            return "path";
        // One line that reads like a command or code: mono.
        if (!t.includes("\n") && /^(sudo |\$ |[a-z][\w.-]* -{1,2}\w)|[{};=|&<>`]|::|=>/.test(t))
            return "code";
        return "text";
    }

    function _entry(id, text, pinned, seen) {
        const kind = _kind(text);
        let label = text.replace(/\s+/g, " ").trim();
        if (kind === "image") {
            const m = /(\d+)x(\d+)/.exec(text);
            label = m ? `Image · ${m[1]} × ${m[2]}` : "Image";
        }
        return { id: id, line: id === null ? "" : `${id}\t${text}`, text: text, label: label, kind: kind, pinned: pinned, seen: seen ?? null };
    }

    // ── cliphist ────────────────────────────────────────────────
    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now();
                const seen = Object.assign({}, store.seen ?? {});
                const first = Object.keys(seen).length === 0 && !store.started;
                const out = [];
                const keep = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    if (!(id in seen) && !first)
                        seen[id] = now;
                    keep[id] = seen[id] ?? 0;
                    if (out.length < root.limit)
                        out.push(root._entry(id, line.slice(tab + 1), false, seen[id]));
                }
                root.history = out;
                store.seen = keep;
                store.started = true;
            }
        }
    }

    // Any change to the clipboard: list again (debounced).
    Process {
        id: watch
        running: true
        command: ["wl-paste", "--watch", "echo"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
        onExited: restart.start()
    }
    Timer {
        id: restart
        interval: 5000
        onTriggered: watch.running = true
    }
    Timer {
        id: debounce
        // cliphist stores the entry from its own watcher; give it a moment.
        interval: 250
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    FileView {
        path: root.dataDir + "/clipboard.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property var pins: []          // [{ text, at }]
            property var seen: ({})        // cliphist id → when Reef first saw it (ms)
            property bool started: false   // the first listing ran (its entries have no time)
        }
    }
}
