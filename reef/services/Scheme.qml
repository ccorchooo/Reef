pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import "schemegen.js" as Gen

// The color scheme (DESIGN.md §3). Colors.qml binds to `scheme`; null means "use the
// reference scheme in tokens".
//
// Palette (look.palette):
//   wallpaper  M3 roles generated in Reef (schemegen.js) from the wallpaper's colors, read
//              with ColorQuantizer, or from look.staticColor when one is set. Colorfulness
//              (look.colorfulness: monochrome | neutral | tinted | vivid | deep) sets how much
//              color the accents and surfaces carry. A second wallpaper color, when the picture
//              has one, becomes the tertiary accent.
//   <id>       a classic palette from tokens (Gruvbox, Catppuccin, …), in its own dark and
//              light variants; Colorfulness doesn't apply.
//
// The last scheme is cached in ~/.cache/reef/scheme.json so the next start shows it before
// the wallpaper has been read.
Singleton {
    id: root

    // { source: {...}, dark: { primary: "#…", … }, light: { … } } or null
    readonly property var scheme: _scheme
    // True while the wallpaper is being read.
    readonly property bool busy: _wantsWallpaper && _readFor !== _wallpaperUrl
    property string lastError: ""

    // The wallpaper's seed colors, most prominent first (hex), for Settings → Look.
    readonly property var seeds: _seeds
    // The seed the wallpaper scheme uses.
    readonly property string seed: Config.options.look.staticColor !== "" ? Config.options.look.staticColor
        : _seeds.length > 0 ? _seeds[0] : Tokens.seed

    readonly property string cachePath: Config.cacheDir + "/scheme.json"

    readonly property var source: ({
            palette: Config.options.look.palette,
            wallpaper: Config.options.look.wallpaper,
            staticColor: Config.options.look.staticColor,
            colorfulness: Config.options.look.colorfulness
        })

    function regenerate() {
        _update();
    }

    property var _scheme: null
    property var _seeds: []
    property string _readFor: ""

    readonly property bool _classic: Tokens.paletteIds.includes(source.palette)
    readonly property bool _wantsWallpaper: !_classic && source.staticColor === "" && source.wallpaper !== ""
    readonly property string _wallpaperUrl: source.wallpaper !== "" ? "file://" + source.wallpaper : ""

    ColorQuantizer {
        id: quantizer
        source: root._wallpaperUrl
        depth: 4                 // 16 buckets, each about a sixteenth of the picture
        rescaleSize: 96
        onColorsChanged: {
            root._seeds = Gen.seeds(Array.from(colors ?? []));
            root._readFor = root._wallpaperUrl;
            root._update();
        }
    }
    on_WallpaperUrlChanged: {
        _seeds = [];
        _readFor = "";
    }

    onSourceChanged: if (Config.loaded) debounce.restart()
    Connections {
        target: Config
        function onLoadedChanged() { if (Config.loaded) debounce.restart(); }
    }

    Timer {
        id: debounce
        interval: 50
        onTriggered: root._update()
    }

    function _sameSource(a, b) {
        return a && b && a.palette === b.palette && a.wallpaper === b.wallpaper && a.staticColor === b.staticColor && a.colorfulness === b.colorfulness;
    }

    function _update() {
        if (!Config.loaded)
            return;
        const s = source;
        try {
            let next;
            if (_classic) {
                const p = Tokens.palettes[s.palette];
                next = { dark: Gen.classic(p.dark, true), light: Gen.classic(p.light, false) };
            } else if (s.staticColor === "" && s.wallpaper === "" && s.colorfulness !== "monochrome") {
                _scheme = null;          // the reference scheme
                return;
            } else {
                // Wait for the wallpaper's colors; until then the cached scheme stays.
                if (_wantsWallpaper && _readFor !== _wallpaperUrl)
                    return;
                const seed = s.staticColor !== "" ? s.staticColor : _seeds[0] ?? Tokens.seed;
                const tertiary = s.staticColor === "" ? _seeds[1] ?? "" : "";
                next = Gen.generate(seed, tertiary, s.colorfulness);
            }
            next.source = s;
            lastError = "";
            _scheme = next;
            cache.setText(JSON.stringify(next, null, 1));
        } catch (e) {
            lastError = "Could not build the color scheme: " + e;
            console.warn("Scheme:", lastError);
        }
    }

    // Cache: read at start for an instant scheme, written after each change.
    FileView {
        id: cache
        path: root.cachePath
        printErrors: false          // missing on first run; that's fine
        onLoaded: {
            try {
                const c = JSON.parse(text());
                // Before Config loads, trust the cache; _update() replaces it once it has.
                const fresh = !Config.loaded || root._sameSource(c.source, root.source);
                if (c && c.dark && c.light && !root._scheme && fresh)
                    root._scheme = c;
            } catch (e) {}
        }
    }
}
