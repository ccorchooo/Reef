pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Pinned and running apps for the Dock cay, and when each app was last opened
// (for search; kept in ~/.cache/reef/launches.json).
// Pins are desktop entry ids in bar.pinnedApps, changed from the app menu (right-click a
// Dock tile or an app in search) or Settings → Apps. Until the pins are first edited
// (bar.pinsEdited), Reef pins the first installed terminal, file manager, browser, editor
// and music app. Apps in apps.hidden aren't listed in search.
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
        if (Config.options.bar.pinsEdited)
            return Array.from(Config.options.bar.pinnedApps).filter(id => !!DesktopEntries.byId(id));
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

    // ── pins ────────────────────────────────────────────────────
    function isPinned(id) {
        return pinnedIds.includes(id);
    }

    function _setPins(list) {
        Config.options.bar.pinnedApps = list;
        Config.options.bar.pinsEdited = true;
    }

    function pin(id) {
        if (id && !isPinned(id))
            _setPins(pinnedIds.concat([id]));
    }

    function unpin(id) {
        _setPins(pinnedIds.filter(p => p !== id));
    }

    function togglePin(id) {
        isPinned(id) ? unpin(id) : pin(id);
    }

    // Moves a pin by `by` places (−1 = toward the start of the Dock).
    function movePin(id, by) {
        const list = pinnedIds.slice();
        const i = list.indexOf(id), j = i + by;
        if (i < 0 || j < 0 || j >= list.length)
            return;
        list.splice(i, 1);
        list.splice(j, 0, id);
        _setPins(list);
    }

    // ── search visibility ───────────────────────────────────────
    function isHidden(id) {
        return Config.options.apps.hidden.includes(id);
    }

    function setHidden(id, hidden) {
        const list = Array.from(Config.options.apps.hidden).filter(h => h !== id);
        if (hidden)
            list.push(id);
        Config.options.apps.hidden = list;
    }

    // The windows open for a desktop entry id.
    function windowsOf(id) {
        return dock.find(i => i.id === id)?.toplevels ?? [];
    }

    function closeWindows(id) {
        for (const t of windowsOf(id))
            t.close();
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
