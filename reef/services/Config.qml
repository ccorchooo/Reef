pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings, backed by ~/.config/reef/config.json.
// Missing keys fall back to the defaults below; the file is created on first run
// and reloaded live when it changes on disk. Change a value from QML with
// `Config.options.motion.speed = 1.5` and it is written back automatically.
Singleton {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    readonly property string dir: configHome + "/reef"
    readonly property string path: dir + "/config.json"
    readonly property string cacheDir: cacheHome + "/reef"   // FileView creates it on first write

    readonly property alias options: adapter
    // True once settings are usable: the file was read, or it was missing and defaults were written.
    readonly property bool loaded: _ready
    property bool _ready: false

    // Per-monitor settings: defaults merged with config.monitors[<output name>].
    function monitor(name) {
        const m = adapter.monitors?.[name] ?? {};
        return {
            showBar: m.showBar ?? true,
            showIsland: m.showIsland ?? true,
            showCorners: m.showCorners ?? true,
            barPosition: m.barPosition ?? "bottom"
        };
    }

    function setMonitor(name, key, value) {
        const all = Object.assign({}, adapter.monitors);
        all[name] = Object.assign({}, all[name] ?? {}, { [key]: value });
        adapter.monitors = all;
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        atomicWrites: true
        printErrors: false          // load failures are handled below
        onFileChanged: reload()
        onLoaded: root._ready = true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
                root._ready = true;
            } else {
                console.warn("Config: could not read", root.path, "-", FileViewError.toString(error));
                root._ready = true; // run on defaults
            }
        }

        JsonAdapter {
            id: adapter

            // Settings → Look
            property JsonObject look: JsonObject {
                property string colorfulness: "tinted"   // neutral | tinted | vivid
                property string theme: "dark"            // auto | light | dark
                property string autoLightAt: "07:00"     // used when theme is auto
                property string autoDarkAt: "19:00"
                property string transparency: "solid"    // solid | frosted
                property string staticColor: ""          // a hex seed; empty = from the wallpaper
                property string wallpaper: ""            // image path the scheme is generated from
                property string homeLogo: "reef"         // reef | distro | custom
                property string homeLogoPath: ""
            }

            // Settings → Scale (multipliers on the tokens)
            property JsonObject scale: JsonObject {
                property real text: 1
                property real spacing: 1
                property real corners: 1
            }

            // Settings → Motion
            property JsonObject motion: JsonObject {
                property bool reduceMotion: false
                property real speed: 1                   // animation speed multiplier; 2 = twice as fast
                property bool islandHoverReveal: true
            }

            // Settings → Power & performance
            property JsonObject performance: JsonObject {
                property bool blur: true
                property bool shapeMorphs: true          // false = crossfade instead of morphing
                property bool visualizer: true           // cava-driven waveforms (Island, Pearl)
                property int visualizerFps: 30
            }

            // Settings → Bar & Island
            property JsonObject bar: JsonObject {
                property bool showSpotlight: true
                property list<string> pinnedApps: []     // desktop entry ids; empty = sensible defaults
                property int workspaceCount: 5           // always shown in the Navigator; more appear when used
                property string clockFormat: "hh:mm"     // Qt time format
            }

            property JsonObject island: JsonObject {
                property bool detectRecording: true      // show other apps' screen recordings as an activity
                property bool peek: true                 // hover the resting Island to peek at the activity
                // Which live activities the Island shows.
                property JsonObject activities: JsonObject {
                    property bool recording: true
                    property bool screenShare: true
                    property bool micCamera: true
                    property bool battery: true          // low battery and charging
                    property bool bluetooth: true        // a device connects
                    property bool timer: true
                    property bool stopwatch: true
                    property bool media: true
                    property bool keepAwake: true
                }
            }

            property JsonObject battery: JsonObject {
                property real lowLevel: 0.15             // "low battery" activity at or below this
                property real criticalLevel: 0.05
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true              // volume and brightness OSD on the right edge
            }

            property JsonObject toasts: JsonObject {
                property bool enabled: true
            }

            // Settings → Displays: { "<output>": { showBar, showIsland, showCorners, barPosition } }
            property var monitors: ({})

            property JsonObject debug: JsonObject {
                property bool devWindow: false           // the M0 token/motion/shape inspector
            }
        }
    }
}
