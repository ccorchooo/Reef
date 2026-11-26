import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Power & performance: the session, the battery, and what Reef spends on
// looks.
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var perf: Config.options.performance

    SettingsSection {
        width: parent.width
        title: "Session"
        SwitchRow {
            width: parent.width
            text: "Authentication dialog"
            description: "Reef answers apps that ask for your password. Only one program can."
            checked: Config.options.session.polkitAgent
            onToggled: Config.options.session.polkitAgent = !checked
        }
    }

    SettingsSection {
        width: parent.width
        title: "Battery"
        visible: Battery.present
        SliderRow {
            width: parent.width
            text: "Low battery"
            icon: "battery_alert"
            from: 5
            to: 40
            stepSize: 5
            value: Math.round(Config.options.battery.lowLevel * 100)
            format: v => `${v}%`
            onMoved: v => Config.options.battery.lowLevel = v / 100
        }
    }

    SettingsSection {
        width: parent.width
        title: "Performance"
        SwitchRow {
            width: parent.width
            text: "Blur"
            description: "Used by Frosted transparency."
            checked: root.perf.blur
            onToggled: Config.options.performance.blur = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Shape morphs"
            description: "Off: shapes crossfade instead."
            checked: root.perf.shapeMorphs
            onToggled: Config.options.performance.shapeMorphs = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Audio visualizer"
            checked: root.perf.visualizer
            onToggled: Config.options.performance.visualizer = !checked
        }
        SliderRow {
            width: parent.width
            visible: root.perf.visualizer
            text: "Visualizer frame rate"
            icon: "graphic_eq"
            from: 10
            to: 60
            stepSize: 5
            value: root.perf.visualizerFps
            format: v => `${v} fps`
            onMoved: v => Config.options.performance.visualizerFps = v
        }
        SwitchRow {
            width: parent.width
            text: "Live window thumbnails"
            description: "Off: the overview and switcher show one still frame per window."
            checked: root.perf.liveThumbnails
            onToggled: Config.options.performance.liveThumbnails = !checked
        }
    }
}
