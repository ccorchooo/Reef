pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The Shelf (SURFACES.md → The Island; parts/Island-Shelf): files and text dropped on
// the Island, kept until dragged out, removed or cleared. Files stay where they are
// (the Shelf holds their paths); text is kept as is. The list lives in
// $XDG_RUNTIME_DIR/reef/shelf.json, so it survives a reload and goes with the session.
//
//   Shelf.addDrop(drop)    // from a DropArea
//   Shelf.items            // [{ kind: file | image | folder | text, path, name, text }]
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/reef"
    readonly property var items: store.items ?? []
    readonly property int count: items.length

    readonly property var imageTypes: ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "heic", "tif", "tiff"]

    function addDrop(drop) {
        const added = [];
        if (drop.hasUrls) {
            for (const u of drop.urls) {
                const url = String(u);
                if (!url.startsWith("file://"))
                    continue;
                const path = decodeURIComponent(url.slice("file://".length));
                if (!items.some(i => i.path === path) && !added.some(i => i.path === path))
                    added.push(_file(path));
            }
        } else if (drop.hasText && drop.text.trim() !== "") {
            added.push({ kind: "text", path: "", name: "", text: drop.text });
        }
        if (added.length > 0)
            store.items = items.concat(added);
        return added.length;
    }

    function addText(text) {
        if (text.trim() !== "")
            store.items = items.concat([{ kind: "text", path: "", name: "", text: text }]);
    }

    function remove(index) {
        const out = items.slice();
        out.splice(index, 1);
        store.items = out;
    }

    function clear() {
        store.items = [];
    }

    function _file(path) {
        const name = path.replace(/\/+$/, "").split("/").pop();
        const dot = name.lastIndexOf(".");
        const ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
        // A trailing slash or no extension is likely a folder; it's only an icon.
        const kind = path.endsWith("/") ? "folder" : imageTypes.includes(ext) ? "image" : "file";
        return { kind: kind, path: path, name: name, text: "" };
    }

    FileView {
        path: root.dir + "/shelf.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property var items: []
        }
    }
}
