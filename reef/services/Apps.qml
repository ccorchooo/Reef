pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Pinned and running apps for the Dock cay, and when each app was last opened
// (for search; kept in ~/.cache/reef/launches.json).
// Pins come from Settings → Bar → Pinned apps (desktop entry ids). With none set,
// Reef pins the first installed terminal, file manager, browser, editor and music app.
Singleton {
    id: root

    readonly property var defaultCandidates: [
        ["kitty", "foot", "Alacritty", "com.mitchellh.ghostty", "org.wezfurlong.wezterm", "org.gnome.Console"],
        ["org.gnome.Nautilus", "thunar", "org.kde.dolphin", "nemo"],
        ["firefox", "zen", "chromium", "brave-browser", "google-chrome"],
        ["code", "code-oss", "codium", "dev.zed.Zed"],
        ["spotify", "org.gnome.Rhythmbox3", "io.bassi.Amberol", "org.gnome.Music"]
    ]

    // Desktop entries load asynchronously; reading the list makes these bindings re-run.
    readonly property int _entries: DesktopEntries.applications.values.length

    readonly property var pinnedIds: {
        _entries;
        const configured = Config.options.bar.pinnedApps;
        if (configured.length > 0)
            return configured.filter(id => !!DesktopEntries.byId(id));
        const out = [];
        for (const group of defaultCandidates) {
            const id = group.find(id => !!DesktopEntries.byId(id));
            if (id)
                out.push(id);
        }
        return out;
    }

    readonly property var toplevels: ToplevelManager.toplevels.values

    // [{ id, entry, toplevels, running, focused }]: pins first, then running unpinned apps.
    readonly property var dock: {
        _entries;
        const items = pinnedIds.map(id => ({ id: id, entry: DesktopEntries.byId(id), toplevels: [] }));
        for (const t of toplevels) {
            const entry = entryFor(t.appId);
            const key = entry?.id ?? t.appId;
            let item = items.find(i => i.id === key || (i.entry && entry && i.entry.id === entry.id));
            if (!item) {
                item = { id: key, entry: entry, toplevels: [] };
                items.push(item);
            }
            item.toplevels.push(t);
        }
        for (const i of items) {
            i.running = i.toplevels.length > 0;
            i.focused = i.toplevels.some(t => t.activated);
        }
        return items;
    }

    function entryFor(appId) {
        if (!appId)
            return null;
        return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId);
    }

    function iconFor(item) {
        return Quickshell.iconPath(item.entry?.icon ?? item.id, "application-x-executable");
    }

    function nameFor(item) {
        return item.entry?.name ?? item.id;
    }

    // Launch, focus, or cycle through an app's windows.
    function activate(item) {
        if (item.toplevels.length === 0) {
            if (item.entry)
                launch(item.entry);
            return;
        }
        const i = item.toplevels.findIndex(t => t.activated);
        item.toplevels[(i + 1) % item.toplevels.length].activate();
    }

    // ── launching ───────────────────────────────────────────────
    // entry id → when it was last opened (ms since epoch).
    readonly property var lastOpened: launches.lastOpened

    function launch(entry) {
        entry.execute();
        const m = Object.assign({}, launches.lastOpened);
        m[entry.id] = Date.now();
        launches.lastOpened = m;
    }

    FileView {
        path: Config.cacheDir + "/launches.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: launches
            property var lastOpened: ({})
        }
    }
}
