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
            showWidgets: m.showWidgets ?? true,
            barPosition: m.barPosition ?? "bottom"
        };
    }

    // Home widgets on a monitor: [{ id, kind, x, y }] (x, y from the free desktop's
    // top-left). null until edit mode saves a layout there; the default layout is used.
    function widgets(name) {
        return adapter.home.layouts?.[name] ?? null;
    }

    function setWidgets(name, list) {
        const all = Object.assign({}, adapter.home.layouts);
        all[name] = list;
        adapter.home.layouts = all;
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
                property string palette: "wallpaper"     // wallpaper | a classic palette id from tokens (gruvbox, catppuccin, …)
                property string colorfulness: "tinted"   // monochrome | neutral | tinted | vivid | deep (wallpaper palette only)
                property string theme: "dark"            // auto | light | dark
                property string autoLightAt: "07:00"     // used when theme is auto
                property string autoDarkAt: "19:00"
                property string transparency: "solid"    // solid | frosted
                property string staticColor: ""          // a hex seed; empty = from the wallpaper
                property string wallpaper: ""            // image path the scheme is generated from
                property string homeLogo: "reef"         // reef | distro | custom
                property string homeLogoPath: ""
                property bool drawWallpaper: false       // Reef draws look.wallpaper itself (off: another program does)
            }

            // Settings → Scale (multipliers on the tokens)
            property JsonObject scale: JsonObject {
                property real zoom: 1                    // the whole shell: sizes, spacing, corners and text
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
                property bool liveThumbnails: true       // overview/switcher windows update live; off = one still frame
            }

            // Settings → Bar & Island
            property JsonObject bar: JsonObject {
                property bool showSpotlight: true
                // Cay order: before "|" from the start of the bar, after it from the far end.
                property list<string> cays: ["dock", "navigator", "workspaces", "spotlight", "|", "status"]
                property bool workspacesCay: false       // workspace numbers in their own cay, always shown
                // What the Spotlight cay shows: the first of these that's live, else `fallback`.
                property JsonObject spotlight: JsonObject {
                    property bool media: true
                    property bool timers: true           // a timer or the stopwatch
                    property bool events: true           // today's next calendar event
                    property string fallback: "weather"  // weather | system | none
                }
                property list<string> pinnedApps: []     // desktop entry ids, in Dock order
                property bool pinsEdited: false          // false = pin sensible defaults (pinnedApps is ignored)
                property int workspaceCount: 5           // always shown in the Navigator; more appear when used
                property string clockFormat: "hh:mm"     // Qt time format
                property bool statusBluetooth: true      // a Bluetooth item in the Status cay (with an adapter)
                property bool statusMenusOnHover: true   // rest on a Status item to open its menu; off = click it
                property bool panelsPushBar: true        // Tide panels move the cays aside instead of covering them
            }

            // Settings → Bar & Island → Control center: the quick toggles in order. Wide ones
            // (wifi, bluetooth, keepAwake, focus) take two of the four columns. Edit mode
            // rearranges them.
            property JsonObject controlCenter: JsonObject {
                property list<string> tiles: ["wifi", "bluetooth", "dnd", "nightLight", "screenshot", "micMute", "keepAwake", "focus"]
            }

            // Home widgets (edit mode). Per-monitor on/off is monitors.<output>.showWidgets.
            property JsonObject home: JsonObject {
                property var layouts: ({})               // { "<output>": [ { id, kind, x, y } ] }; missing = default layout
                property string weatherLocation: ""      // a city for wttr.in; empty = guessed from the IP address
                property string temperatureUnit: "c"     // c | f
                property bool wiggle: true               // widgets wiggle in edit mode (never with Reduce motion)
                // Settings → Widgets → Clock
                property JsonObject clock: JsonObject {
                    property string shape: "circle"      // a Shapes name: circle | squircle | cookie4 | cookie6 | cookie9 | cookie12 | sunny | flower | clover8
                    property string numbers: "none"      // none | quarters | all | hour (the current hour, large behind the hands)
                    property bool ticks: true            // hour ticks around the edge
                    property bool seconds: false         // a second hand
                    property string color: "surface"     // surface | primary | secondary | tertiary (the face's container color)
                }
            }

            property JsonObject island: JsonObject {
                property bool detectRecording: true      // show other apps' screen recordings as an activity
                property bool peek: true                 // hover the resting Island to peek at the activity
                property bool dropToShelf: true          // dropping files or text on the Island keeps them on the Shelf
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
                    property bool progress: true         // notifications reporting progress
                    property bool event: true            // calendar event starting soon
                    property bool focus: true            // focus session
                }
            }

            // Settings → Lock screen
            property JsonObject lock: JsonObject {
                property bool activity: true             // the Island's main activity inside the Pearl (media: a player)
                property bool status: true               // network, battery and keyboard layout, bottom right
                property bool powerButtons: true         // Sleep, Power off and Restart beside the field
                property bool onLidClose: true           // closing the laptop lid locks the session
                // The Pearl (lock screen, power actions, Settings → Lock screen)
                property JsonObject pearl: JsonObject {
                    property string shape: "cookie9"     // a Shapes name (as home.clock.shape)
                    property string color: "island"      // island (black) | primary | secondary | tertiary (container)
                    property string face: "digital"      // digital | analog | stats: what it shows with no activity
                    property bool date: true             // the date under the digital clock
                    property bool hop: true              // hops on the minute and when its activity changes
                }
            }

            // Settings → Power & session
            property JsonObject session: JsonObject {
                property bool lockBeforeSleep: true      // Sleep from the power actions locks first
                property bool polkitAgent: true          // Reef answers polkit prompts (only one agent per session)
            }

            property JsonObject battery: JsonObject {
                property real lowLevel: 0.15             // "low battery" activity at or below this
                property real criticalLevel: 0.05
            }

            // Settings → Notifications
            property JsonObject notifications: JsonObject {
                property bool dnd: false                 // Do not disturb
            }

            property JsonObject focus: JsonObject {
                property int focusMinutes: 25
                property int breakMinutes: 5
            }

            property JsonObject nightLight: JsonObject {
                property bool enabled: false
                property int temperature: 4000           // kelvin; lower is warmer
            }

            // Settings → Calendar: .ics files or https links
            property JsonObject calendar: JsonObject {
                property list<string> sources: []
            }

            // Settings → Bar & Island → Clipboard
            property JsonObject clipboard: JsonObject {
                property int limit: 200                  // entries the Clipboard tab lists (cliphist keeps its own)
            }

            property JsonObject screenshots: JsonObject {
                property string folder: ""               // empty = ~/Pictures/Screenshots
            }

            // Settings → Apps
            property JsonObject apps: JsonObject {
                property list<string> hidden: []         // desktop entry ids search doesn't list
            }

            // Settings → Search
            property JsonObject search: JsonObject {
                property bool files: true                // look for files in the home folder
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true              // volume and brightness OSD on the right edge
            }

            property JsonObject toasts: JsonObject {
                property bool enabled: true
            }

            // Settings → Displays: { "<output>": { showBar, showIsland, showCorners, barPosition } }
            property var monitors: ({})

            // Settings → Coral (the assistant arrives in M8)
            property JsonObject coral: JsonObject {
                property string endpoint: "http://localhost:11434/v1"   // any OpenAI-compatible API
                property string model: ""
                property string apiKeyEnv: "OPENAI_API_KEY"   // the environment variable holding the key (never stored here)
                property bool voice: true
            }

            property JsonObject debug: JsonObject {
                property bool devWindow: false           // the M0 token/motion/shape inspector
            }
        }
    }
}
