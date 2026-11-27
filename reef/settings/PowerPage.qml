import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Power & performance: the session, the battery, and what Reef spends on
// looks. Performance mode (always, or on battery) turns the heavy effects off at once
// (services/Performance); the switches under it are what applies the rest of the time.
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
        id: idleSection
        title: "When idle"
        readonly property var idle: Config.options.idle
        readonly property var after: v => v === 0 ? "Never" : `${v} min`
        SwitchRow {
            width: parent.width
            text: "Act when idle"
            description: "Keep awake, fullscreen video and games hold it off."
            checked: idleSection.idle.enabled
            onToggled: Config.options.idle.enabled = !checked
        }
        SliderRow {
            width: parent.width
            visible: idleSection.idle.enabled
            text: "Lock after"
            icon: "lock"
            from: 0
            to: 30
            stepSize: 1
            value: idleSection.idle.lockMinutes
            format: idleSection.after
            onMoved: v => Config.options.idle.lockMinutes = v
        }
        SliderRow {
            width: parent.width
            visible: idleSection.idle.enabled
            text: "Screens off after"
            icon: "desktop_access_disabled"
            from: 0
            to: 60
            stepSize: 1
            value: idleSection.idle.screenOffMinutes
            format: idleSection.after
            onMoved: v => Config.options.idle.screenOffMinutes = v
        }
        SliderRow {
            width: parent.width
            visible: idleSection.idle.enabled
            text: Battery.present ? "Sleep after, plugged in" : "Sleep after"
            icon: "bedtime"
            from: 0
            to: 120
            stepSize: 5
            value: idleSection.idle.suspendMinutes
            format: idleSection.after
            onMoved: v => Config.options.idle.suspendMinutes = v
        }
        SliderRow {
            width: parent.width
            visible: idleSection.idle.enabled && Battery.present
            text: "Sleep after, on battery"
            icon: "battery_horiz_050"
            from: 0
            to: 120
            stepSize: 5
            value: idleSection.idle.suspendOnBatteryMinutes
            format: idleSection.after
            onMoved: v => Config.options.idle.suspendOnBatteryMinutes = v
        }
        SwitchRow {
            width: parent.width
            visible: idleSection.idle.enabled
            text: "Lock and sleep while media plays"
            checked: idleSection.idle.whileMedia
            onToggled: Config.options.idle.whileMedia = !checked
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
        Column {
            width: parent.width
            spacing: Tokens.space2
            StyledText {
                style: "rowLabel"
                text: "Performance mode"
            }
            SegmentedButtons {
                width: parent.width
                label: "Performance mode"
                options: Battery.present
                    ? [{ value: "off", label: "Off" }, { value: "battery", label: "On battery" }, { value: "on", label: "On" }]
                    : [{ value: "off", label: "Off" }, { value: "on", label: "On" }]
                current: root.perf.mode === "battery" && !Battery.present ? "off" : root.perf.mode
                onSelected: v => Config.options.performance.mode = v
            }
            StyledText {
                width: parent.width
                style: "bodySm"
                color: Colors.on.surfaceVariant
                wrapMode: Text.Wrap
                text: Performance.active
                    ? "On now: blur, shape morphs, the visualizer, live thumbnails and the wiggle and hop are off."
                    : "Off now: the switches below apply."
            }
        }
        SwitchRow {
            width: parent.width
            text: "Blur"
            description: "Behind the power actions and the overview."
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
