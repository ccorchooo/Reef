pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Default apps (Settings → Apps): which app opens links, folders, text, pictures, … .
// Reads and sets them with xdg-mime (xdg-utils), so every program that opens files
// through xdg-open or GIO follows. The terminal has no MIME type; it's kept in
// ~/.config/xdg-terminals.list (the xdg-terminal-exec list) instead.
//
// Candidates for a kind are the apps whose desktop file lists its MIME type, plus the
// apps in its categories. Nothing runs until `refresh()` (Settings → Apps calls it).
Singleton {
    id: root

    readonly property var kinds: [
        { id: "browser", label: "Web browser", icon: "language", mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"], categories: ["WebBrowser"] },
        { id: "files", label: "Files", icon: "folder", mimes: ["inode/directory"], categories: ["FileManager"] },
        { id: "terminal", label: "Terminal", icon: "terminal", mimes: [], categories: ["TerminalEmulator"] },
        { id: "mail", label: "Email", icon: "mail", mimes: ["x-scheme-handler/mailto"], categories: ["Email"] },
        { id: "text", label: "Text editor", icon: "edit_note", mimes: ["text/plain"], categories: ["TextEditor"] },
        { id: "images", label: "Images", icon: "image", mimes: ["image/png", "image/jpeg", "image/webp", "image/gif"], categories: [] },
        { id: "video", label: "Videos", icon: "movie", mimes: ["video/mp4", "video/x-matroska", "video/webm"], categories: [] },
        { id: "music", label: "Music", icon: "music_note", mimes: ["audio/mpeg", "audio/flac", "audio/ogg"], categories: [] },
        { id: "pdf", label: "PDF documents", icon: "picture_as_pdf", mimes: ["application/pdf"], categories: [] }
    ]

    // kind id → desktop entry id (no ".desktop"), "" when none is set.
    property var current: ({})
    // desktop entry id → [MIME types] from the desktop files.
    property var _mimes: ({})
    readonly property bool loading: query.running || mimeIndex.running

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string terminalList: configHome + "/xdg-terminals.list"

    // Desktop entries that can handle a kind, by name.
    function candidates(kindId) {
        DesktopEntries.applications.values.length;          // re-run as entries load
        const kind = kinds.find(k => k.id === kindId);
        if (!kind)
            return [];
        const want = kind.mimes[0];
        return DesktopEntries.applications.values
            .filter(e => (want && (_mimes[e.id] ?? []).includes(want)) || kind.categories.some(c => (e.categories ?? []).includes(c)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function entryFor(kindId) {
        const id = current[kindId];
        return id ? DesktopEntries.byId(id) : null;
    }

    function refresh() {
        query.running = false;
        query.running = true;
        mimeIndex.running = false;
        mimeIndex.running = true;
    }

    function set(kindId, entryId) {
        const kind = kinds.find(k => k.id === kindId);
        if (!kind || !entryId)
            return;
        if (kindId === "terminal") {
            terminalFile.setText(entryId + ".desktop\n");
        } else {
            setter.command = ["xdg-mime", "default", entryId + ".desktop"].concat(kind.mimes);
            setter.running = true;
        }
        const next = Object.assign({}, current);
        next[kindId] = entryId;
        current = next;
    }

    // One line per kind: "<kind>\t<desktop file>".
    Process {
        id: query
        command: {
            const script = root.kinds.filter(k => k.mimes.length > 0)
                .map(k => `printf '%s\\t%s\\n' ${k.id} "$(xdg-mime query default ${k.mimes[0]} 2>/dev/null)"`).join("; ");
            return ["sh", "-c", script];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const next = Object.assign({}, root.current);
                for (const line of text.split("\n")) {
                    const [kind, file] = line.split("\t");
                    if (kind)
                        next[kind] = (file ?? "").replace(/\.desktop$/, "");
                }
                root.current = next;
                terminalFile.reload();
            }
        }
    }

    // MimeType= lines of every desktop file in the usual places.
    Process {
        id: mimeIndex
        command: ["sh", "-c", "for d in \"$@\"; do grep -H '^MimeType=' \"$d\"/*.desktop 2>/dev/null; done; true", "sh",
            Quickshell.env("HOME") + "/.local/share/applications", "/usr/share/applications", "/usr/local/share/applications",
            "/var/lib/flatpak/exports/share/applications", Quickshell.env("HOME") + "/.local/share/flatpak/exports/share/applications"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const at = line.indexOf(":MimeType=");
                    if (at < 0)
                        continue;
                    const id = line.slice(line.lastIndexOf("/", at) + 1, at).replace(/\.desktop$/, "");
                    if (!(id in map))
                        map[id] = line.slice(at + 10).split(";").filter(m => m !== "");
                }
                root._mimes = map;
            }
        }
    }

    Process {
        id: setter
        onExited: code => {
            if (code !== 0)
                console.warn("DefaultApps: xdg-mime failed with", code);
        }
    }

    FileView {
        id: terminalFile
        path: root.terminalList
        printErrors: false
        onLoaded: {
            const first = text().split("\n").map(l => l.trim()).find(l => l !== "" && !l.startsWith("#")) ?? "";
            const next = Object.assign({}, root.current);
            next.terminal = first.replace(/^[+-]/, "").replace(/\.desktop$/, "").replace(/:.*$/, "");
            root.current = next;
        }
    }
}
