pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Search results (SURFACES.md → Search; screens/Search). The search panel sets `query`
// and `active`, shows `sections` and calls activate(). Sections, in order: Apps,
// Settings, Files (from `find` in the home folder), Coral. A query starting with "/"
// lists commands instead: the built actions (Actions) plus /scheme.
//
// Each result: { kind, title, subtitle, icon, iconSource, run }; apps also carry
// `entryId` (for the app menu). Apps hidden in Settings → Apps aren't listed.
Singleton {
    id: root

    property string query: ""
    // True while the panel is open; file search only runs then.
    property bool active: false

    readonly property string text: query.trim()
    readonly property string q: text.toLowerCase()
    readonly property bool commandMode: text.startsWith("/")

    readonly property int maxApps: 5
    readonly property int maxSettings: 3
    readonly property int maxFiles: 4
    readonly property int maxCommands: 8

    // ── matching ────────────────────────────────────────────────
    // 0 = no match; higher is better. Whole word starts beat substrings beat fuzzy
    // (letters in order, only when `fuzzy`: app names).
    function score(haystack, needle, fuzzy) {
        if (!haystack || !needle)
            return 0;
        const h = String(haystack).toLowerCase();
        if (h === needle)
            return 100;
        if (h.startsWith(needle))
            return 80;
        const at = h.indexOf(needle);
        if (at > 0 && /[\s\-_.\/]/.test(h[at - 1]))
            return 60;
        if (at > 0)
            return 40;
        if (!fuzzy || needle.length < 2)
            return 0;
        // Fuzzy: every character of the needle, in order.
        let i = 0;
        for (const c of h) {
            if (c === needle[i])
                i++;
            if (i === needle.length)
                return 10;
        }
        return 0;
    }

    // Matches only at the start of a word (for keyword lists and paths).
    function wordScore(haystack, needle) {
        const s = String(haystack ?? "").split(/[\s›&]+/).reduce((m, w) => Math.max(m, score(w, needle)), 0);
        return s >= 80 ? s : 0;
    }

    function ago(ms) {
        const m = Math.floor((Date.now() - ms) / 60000);
        if (m < 1)
            return "just now";
        if (m < 60)
            return `${m} min ago`;
        const h = Math.floor(m / 60);
        if (h < 24)
            return h === 1 ? "1 hour ago" : `${h} hours ago`;
        const d = Math.floor(h / 24);
        return d === 1 ? "yesterday" : `${d} days ago`;
    }

    // ── apps ────────────────────────────────────────────────────
    function appResult(entry) {
        const last = Apps.lastOpened[entry.id];
        return {
            kind: "app",
            entryId: entry.id,
            title: entry.name,
            subtitle: last ? `App · last opened ${ago(last)}` : (entry.genericName || "App"),
            icon: "",
            iconSource: Quickshell.iconPath(entry.icon, "application-x-executable"),
            run: () => Apps.launch(entry)
        };
    }

    // Nothing is computed while the panel is closed.
    readonly property var apps: {
        if (!active || commandMode)
            return [];
        const hidden = Config.options.apps.hidden;
        const entries = DesktopEntries.applications.values.filter(e => !e.noDisplay && !hidden.includes(e.id));
        const last = Apps.lastOpened;
        if (q === "") {
            // Every app: recently opened first, then the rest A–Z (the panel scrolls).
            const recent = entries.filter(e => last[e.id]).sort((a, b) => last[b.id] - last[a.id]);
            const seen = new Set(recent.map(e => e.id));
            const rest = entries.filter(e => !seen.has(e.id) && (seen.add(e.id), true))
                .sort((a, b) => a.name.localeCompare(b.name));
            return recent.concat(rest).map(appResult);
        }
        const scored = [];
        for (const e of entries) {
            const s = Math.max(score(e.name, q, true), score(e.genericName, q) * 0.7,
                (e.keywords ?? []).reduce((m, k) => Math.max(m, score(k, q) * 0.6), 0),
                score(e.id, q) * 0.5);
            if (s > 0)
                scored.push({ e: e, s: s + (last[e.id] ? 5 : 0) });
        }
        scored.sort((a, b) => b.s - a.s || (last[b.e.id] ?? 0) - (last[a.e.id] ?? 0));
        return scored.slice(0, maxApps).map(x => appResult(x.e));
    }

    // ── settings ────────────────────────────────────────────────
    // Until the Settings app (M9), each setting acts in place: a toggle flips, a menu opens.
    function setTheme(v) { Config.options.look.theme = v; }
    function setColorfulness(v) {
        Config.options.look.palette = "wallpaper";
        Config.options.look.colorfulness = v;
    }

    readonly property var settingsIndex: [
        { title: "Wi-Fi", path: "Network", icon: "wifi", keys: "network internet wireless", run: () => Actions.run("wifiMenu") },
        { title: "Bluetooth", path: "Bluetooth", icon: "bluetooth", keys: "devices headphones pair", run: () => Actions.run("bluetoothMenu") },
        { title: "Sound output", path: "Sound", icon: "speaker", keys: "audio speakers headphones volume", run: () => Actions.run("audioOutput") },
        { title: "Calendar", path: "Calendar", icon: "calendar_month", keys: "events date", run: () => Actions.run("calendar") },
        { title: "Do not disturb", path: "Notifications", icon: "do_not_disturb_on", keys: "dnd quiet silence notifications", on: Notifications.dnd, run: () => Notifications.setDnd(!Notifications.dnd) },
        { title: "Night light", path: "Displays", icon: "nightlight", keys: "warm blue light screen", on: NightLight.enabled, run: () => NightLight.toggle() },
        { title: "Mute microphone", path: "Sound", icon: "mic_off", keys: "mic input", on: Audio.micMuted, run: () => Audio.toggleMicMute() },
        { title: "Keep awake", path: "Power & performance", icon: "coffee", keys: "sleep idle caffeine", on: KeepAwake.active, run: () => KeepAwake.toggle(0) },
        { title: "Focus session", path: "Focus", icon: "self_improvement", keys: "pomodoro work", on: Focus.active, run: () => Focus.active ? Focus.stop() : Focus.start(0) },
        { title: "Dark theme", path: "Look", icon: "dark_mode", keys: "theme appearance", on: Config.options.look.theme === "dark", run: () => root.setTheme("dark") },
        { title: "Light theme", path: "Look", icon: "light_mode", keys: "theme appearance", on: Config.options.look.theme === "light", run: () => root.setTheme("light") },
        { title: "Automatic theme", path: "Look", icon: "brightness_auto", keys: "theme appearance auto schedule", on: Config.options.look.theme === "auto", run: () => root.setTheme("auto") },
        { title: "Monochrome colors", path: "Look", icon: "contrast", keys: "colorfulness scheme gray black white", on: Config.options.look.colorfulness === "monochrome", run: () => root.setColorfulness("monochrome") },
        { title: "Neutral colors", path: "Look", icon: "palette", keys: "colorfulness scheme gray", on: Config.options.look.colorfulness === "neutral", run: () => root.setColorfulness("neutral") },
        { title: "Tinted colors", path: "Look", icon: "palette", keys: "colorfulness scheme", on: Config.options.look.colorfulness === "tinted", run: () => root.setColorfulness("tinted") },
        { title: "Vivid colors", path: "Look", icon: "palette", keys: "colorfulness scheme vibrant", on: Config.options.look.colorfulness === "vivid", run: () => root.setColorfulness("vivid") },
        { title: "Deep colors", path: "Look", icon: "palette", keys: "colorfulness scheme rich saturated wallpaper", on: Config.options.look.colorfulness === "deep", run: () => root.setColorfulness("deep") },
        { title: "Color palette", path: "Look", icon: "format_paint", keys: "gruvbox catppuccin nord tokyo night rose pine everforest solarized dracula theme scheme", run: () => Actions.openSettings("look") },
        { title: "Default apps", path: "Apps", icon: "apps", keys: "browser terminal file manager editor mail open with", run: () => Actions.openSettings("apps") },
        { title: "Clock widget", path: "Widgets", icon: "schedule", keys: "analog face numbers shape seconds home", run: () => Actions.openSettings("widgets") },
        { title: "Reduce motion", path: "Accessibility", icon: "animation", keys: "animations accessibility", on: Config.options.motion.reduceMotion, run: () => Config.options.motion.reduceMotion = !Config.options.motion.reduceMotion },
        { title: "Island peek on hover", path: "Bar & Island", icon: "visibility", keys: "island hover", on: Config.options.island.peek, run: () => Config.options.island.peek = !Config.options.island.peek },
        { title: "Status menus on hover", path: "Bar & Island", icon: "ads_click", keys: "status bar quick menus", on: Config.options.bar.statusMenusOnHover, run: () => Config.options.bar.statusMenusOnHover = !Config.options.bar.statusMenusOnHover },
        { title: "Panels push the bar", path: "Bar & Island", icon: "width", keys: "control center tide", on: Config.options.bar.panelsPushBar, run: () => Config.options.bar.panelsPushBar = !Config.options.bar.panelsPushBar },
        { title: "Volume and brightness OSD", path: "Bar & Island", icon: "tune", keys: "osd overlay", on: Config.options.osd.enabled, run: () => Config.options.osd.enabled = !Config.options.osd.enabled },
        { title: "Live window thumbnails", path: "Power & performance", icon: "preview", keys: "overview switcher alt tab", on: Config.options.performance.liveThumbnails, run: () => Config.options.performance.liveThumbnails = !Config.options.performance.liveThumbnails },
        { title: "Search files", path: "Search", icon: "folder_open", keys: "find documents home", on: Config.options.search.files, run: () => Config.options.search.files = !Config.options.search.files },
        { title: "Toasts", path: "Notifications", icon: "chat_info", keys: "popups messages", on: Config.options.toasts.enabled, run: () => Config.options.toasts.enabled = !Config.options.toasts.enabled }
    ]

    readonly property var settings: {
        if (!active || commandMode || q === "")
            return [];
        return settingsIndex
            .map(s => ({ s: s, score: Math.max(score(s.title, q), wordScore(s.keys, q) * 0.6, wordScore(s.path, q) * 0.5) }))
            .filter(x => x.score > 0)
            .sort((a, b) => b.score - a.score)
            .slice(0, maxSettings)
            .map(x => ({
                kind: "setting",
                title: x.s.title,
                subtitle: `Settings › ${x.s.path}` + (x.s.on === undefined ? "" : x.s.on ? " · On" : " · Off"),
                icon: x.s.icon,
                iconSource: "",
                run: x.s.run
            }));
    }

    // ── commands ("/") ──────────────────────────────────────────
    readonly property var commands: {
        if (!active || !commandMode)
            return [];
        const want = q.slice(1);
        const list = Object.keys(Actions.handlers).map(name => ({ name: name, description: Actions.actions[name]?.[0] ?? name, run: () => Actions.run(name) }));
        list.push({ name: "scheme", description: "Regenerate colors from the wallpaper", run: () => Scheme.regenerate() });
        return list
            .map(c => ({ c: c, score: want === "" ? 1 : Math.max(score(c.name, want), score(c.description, want) * 0.6) }))
            .filter(x => x.score > 0)
            .sort((a, b) => b.score - a.score || a.c.name.localeCompare(b.c.name))
            // A bare "/" lists them all; typing narrows to the best few.
            .slice(0, want === "" ? list.length : maxCommands)
            .map(x => ({ kind: "command", title: "/" + x.c.name, subtitle: x.c.description, icon: "keyboard_command_key", iconSource: "", run: x.c.run }));
    }

    // ── files ───────────────────────────────────────────────────
    readonly property string home: Quickshell.env("HOME")
    property var files: []

    onQChanged: refreshFiles()
    onActiveChanged: refreshFiles()

    function refreshFiles() {
        files = [];
        if (active && Config.options.search.files && !commandMode && q.length >= 2)
            fileDelay.restart();
        else {
            fileDelay.stop();
            finder.running = false;
        }
    }

    Timer {
        id: fileDelay
        interval: Tokens.searchFileDelay
        onTriggered: {
            if (finder.running) {
                finder.restart = true;
                finder.running = false;
            } else {
                root.findFiles();
            }
        }
    }

    function findFiles() {
        // The query is a find pattern, so escape the glob characters.
        const pattern = "*" + text.replace(/[\\*?\[\]]/g, "\\$&") + "*";
        finder.forQuery = q;
        finder.command = ["find", home, "-mindepth", "1", "-maxdepth", "5",
            "(", "-name", ".*", "-o", "-name", "node_modules", "-o", "-name", "__pycache__", ")", "-prune",
            "-o", "-iname", pattern, "-printf", "%y\t%p\n"];
        finder.running = true;
    }

    Process {
        id: finder
        property string forQuery: ""
        property bool restart: false
        stdout: SplitParser {
            onRead: line => {
                if (finder.forQuery !== root.q || root.files.length >= root.maxFiles)
                    return;
                const tab = line.indexOf("\t");
                const path = line.slice(tab + 1);
                const dir = path.slice(0, path.lastIndexOf("/"));
                root.files = root.files.concat([{
                    kind: "file",
                    title: path.slice(path.lastIndexOf("/") + 1),
                    subtitle: dir.startsWith(root.home) ? "~" + dir.slice(root.home.length) : dir,
                    icon: line.startsWith("d") ? "folder" : "description",
                    iconSource: "",
                    run: () => Quickshell.execDetached(["xdg-open", path])
                }]);
                if (root.files.length >= root.maxFiles)
                    finder.running = false;
            }
        }
        onExited: {
            if (restart) {
                restart = false;
                root.findFiles();
            }
        }
    }

    // ── Coral ───────────────────────────────────────────────────
    readonly property var coral: !active || commandMode || q === "" ? [] : ("coral chat conversations assistant ai".split(" ").some(w => w.startsWith(q) && q.length >= 2) ? [{
        kind: "coral",
        title: "Coral",
        subtitle: "Your conversations",
        icon: "",
        iconSource: "",
        run: () => Coral.openApp()
    }] : []).concat([{
        kind: "coral",
        title: `Ask Coral about “${text}”`,
        subtitle: "Answers in the Island",
        icon: "",
        iconSource: "",
        run: (question => () => {
                Coral.ask(question);
                Actions.islandRequested("coral");
            })(text)
    }])

    // ── together ────────────────────────────────────────────────
    readonly property var sections: [
        { title: "Commands", items: commands },
        { title: "Apps", items: apps },
        { title: "Settings", items: settings },
        { title: "Files", items: files },
        { title: "Coral", items: coral }
    ].filter(s => s.items.length > 0)

    // Every result in order, for keyboard selection.
    // Every result in order, each tagged with its section's title (for the headers).
    readonly property var results: sections.reduce((all, s) => all.concat(s.items.map(i => Object.assign({ section: s.title }, i))), [])

    function activate(result) {
        result?.run();
    }
}
