pragma Singleton
import QtQuick
import Quickshell

// What the heavy effects are allowed to do right now (Settings → Power & performance).
// Each switch under performance.* is the user's choice; Performance mode turns them all
// off at once, always (mode "on") or while the laptop runs on its battery or in Power
// saver (mode "battery"). Surfaces read these, never performance.* directly.
//
//   Performance.blur  Performance.shapeMorphs  Performance.visualizer  Performance.liveThumbnails
Singleton {
    id: root

    readonly property var options: Config.options.performance
    readonly property bool active: options.mode === "on"
        || (options.mode === "battery" && (Battery.unplugged || Battery.powerSaver))

    // Compositor blur behind the power actions and the overview (off: the scrim alone).
    readonly property bool blur: options.blur && !active
    // M3E shape morphs (off: crossfades, Motion.shapeMorphs).
    readonly property bool shapeMorphs: options.shapeMorphs && !active
    // The cava waveforms (off: they rest in their drawn shape).
    readonly property bool visualizer: options.visualizer && !active
    readonly property int visualizerFps: options.visualizerFps
    // Overview and switcher windows update live (off: one still frame each).
    readonly property bool liveThumbnails: options.liveThumbnails && !active
    // Constant decorative motion: the widgets' wiggle in edit mode, the Pearl's hop.
    readonly property bool idleMotion: !active
}
