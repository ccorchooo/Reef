pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Generates the M3 color scheme with matugen whenever the wallpaper, static color or
// Colorfulness changes, and keeps it in ~/.cache/reef/scheme.json so the next start
// is instant. Colors.qml binds to `scheme`; null means "use the reference scheme".
//
// Colorfulness → matugen type:
//   tinted  scheme-tonal-spot
//   vivid   scheme-vibrant
//   neutral scheme-tonal-spot accents + scheme-neutral surfaces (DESIGN.md §3)
Singleton {
    id: root

    // { source: {...}, dark: { primary: "#…", … }, light: { … } } or null
    readonly property var scheme: _scheme
    readonly property bool busy: gen.running
    property string lastError: ""

    readonly property string cachePath: Config.cacheDir + "/scheme.json"
    readonly property string matugenConfig: Quickshell.shellDir + "/scripts/matugen.toml"

    readonly property var source: ({
            wallpaper: Config.options.look.wallpaper,
            staticColor: Config.options.look.staticColor,
            colorfulness: Config.options.look.colorfulness
        })

    // Roles taken from the neutral run in Neutral mode.
    readonly property var neutralRoles: ["surface", "onSurface", "onSurfaceVariant", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "outline", "outlineVariant", "inverseSurface", "inverseOnSurface"]

    function regenerate() {
        debounce.restart();
    }

    property var _scheme: null
    property var _queue: []
    property var _result: null

    onSourceChanged: if (Config.loaded) debounce.restart()
    Connections {
        target: Config
        function onLoadedChanged() { if (Config.loaded) debounce.restart(); }
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: root._start()
    }

    function _sameSource(a, b) {
        return a && b && a.wallpaper === b.wallpaper && a.staticColor === b.staticColor && a.colorfulness === b.colorfulness;
    }

    function _start() {
        const s = source;
        if (!s.staticColor && !s.wallpaper) {
            _scheme = null;          // reference scheme
            return;
        }
        if (_scheme && _sameSource(_scheme.source, s))
            return;
        const input = s.staticColor ? ["color", "hex", s.staticColor] : ["image", s.wallpaper, "--prefer", "saturation"];
        const accentType = s.colorfulness === "vivid" ? "scheme-vibrant" : "scheme-tonal-spot";
        _queue = [{ type: accentType, input: input }];
        if (s.colorfulness === "neutral")
            _queue.push({ type: "scheme-neutral", input: input });
        _result = { source: s };
        _next();
    }

    function _next() {
        const job = _queue.shift();
        gen.command = ["matugen"].concat(job.input, ["--dry-run", "--json", "hex", "-t", job.type, "-c", matugenConfig]);
        gen.job = job;
        gen.running = true;
    }

    function _snake(camel) {
        return camel.replace(/[A-Z]/g, c => "_" + c.toLowerCase());
    }

    // matugen 4.x: { colors: { primary: { dark: { color: "#…" }, light: {…} } } }
    function _parse(text) {
        const colors = JSON.parse(text).colors;
        const out = { dark: {}, light: {} };
        for (const role of Object.keys(Tokens.referenceSchemes.dark)) {
            if (Tokens.fixedRoles.includes(role))
                continue;
            const c = colors[_snake(role)];
            if (!c)
                continue;
            for (const mode of ["dark", "light"]) {
                const v = c[mode];
                out[mode][role] = typeof v === "string" ? v : v.color;
            }
        }
        return out;
    }

    Process {
        id: gen
        property var job
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code !== 0) {
                root.lastError = err.text.trim().split("\n").slice(0, 3).join(" ");
                console.warn("Scheme: matugen failed, keeping the current colors.", root.lastError);
                root._queue = [];
                return;
            }
            try {
                const parsed = root._parse(out.text);
                if (gen.job.type === "scheme-neutral") {
                    for (const mode of ["dark", "light"])
                        for (const role of root.neutralRoles)
                            root._result[mode][role] = parsed[mode][role];
                } else {
                    root._result.dark = parsed.dark;
                    root._result.light = parsed.light;
                }
            } catch (e) {
                root.lastError = "Could not read matugen output: " + e;
                console.warn("Scheme:", root.lastError);
                root._queue = [];
                return;
            }
            if (root._queue.length > 0) {
                root._next();
                return;
            }
            root.lastError = "";
            root._scheme = root._result;
            cache.setText(JSON.stringify(root._result, null, 1));
        }
    }

    // Cache: read at start for an instant scheme, written after each generation.
    FileView {
        id: cache
        path: root.cachePath
        printErrors: false          // missing on first run; that's fine
        onLoaded: {
            try {
                const c = JSON.parse(text());
                // Before Config loads, trust the cache; _start() reconciles once it has.
                const fresh = !Config.loaded || root._sameSource(c.source, root.source);
                if (c && c.dark && c.light && !root._scheme && fresh)
                    root._scheme = c;
            } catch (e) {}
        }
    }
}
