pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Emoji for the Tools tab's picker (Super+.). The list is assets/emoji.json (generated
// from Unicode's emoji-test.txt by scripts/gen-emoji.py); recently used ones come first
// and are remembered in $XDG_DATA_HOME/reef/emoji.json.
//
//   Emoji.query = "heart"; Emoji.results; Emoji.copy("❤️")
Singleton {
    id: root

    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/reef"
    readonly property int recentCount: 16

    property string query: ""
    readonly property var all: {
        try {
            return JSON.parse(data.text());
        } catch (e) {
            return [];
        }
    }
    readonly property var recent: recentStore.recent ?? []
    // Recent first when not searching; otherwise names that match, words starting first.
    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "") {
            const rec = recent.map(e => all.find(a => a.e === e)).filter(a => !!a);
            const seen = new Set(recent);
            return rec.concat(all.filter(a => !seen.has(a.e)));
        }
        const starts = [], contains = [];
        for (const a of all) {
            const n = a.n.toLowerCase();
            if (n.startsWith(q) || n.includes(" " + q))
                starts.push(a);
            else if (n.includes(q) || a.g.toLowerCase().includes(q))
                contains.push(a);
        }
        return starts.concat(contains);
    }

    function copy(emoji) {
        Quickshell.execDetached(["wl-copy", "--", emoji]);
        recentStore.recent = [emoji].concat(recent.filter(e => e !== emoji)).slice(0, recentCount);
    }

    FileView {
        id: data
        path: Quickshell.shellPath("assets/emoji.json")
        blockLoading: true
    }

    FileView {
        path: root.dataDir + "/emoji.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: recentStore
            property var recent: []
        }
    }
}
