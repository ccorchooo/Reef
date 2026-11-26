import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules
import qs.modules.bar

// Settings → Bar & Island: the bar, the Island and its activities, home widgets,
// notifications and the smaller tools that live in them.
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var bar: Config.options.bar
    readonly property var island: Config.options.island

    SettingsSection {
        width: parent.width
        title: "Bar"
        Column {
            width: parent.width
            spacing: Tokens.space2
            StyledText {
                style: "rowLabel"
                text: "Cay order"
            }
            CayOrder {
                width: parent.width
            }
        }
        SwitchRow {
            width: parent.width
            text: "Workspaces in their own cay"
            description: "Numbered and always shown; the Navigator's grid button opens the overview."
            checked: root.bar.workspacesCay
            onToggled: Config.options.bar.workspacesCay = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Show Spotlight cay"
            checked: root.bar.showSpotlight
            onToggled: Config.options.bar.showSpotlight = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Bluetooth in the Status cay"
            checked: root.bar.statusBluetooth
            onToggled: Config.options.bar.statusBluetooth = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Status menus on hover"
            description: "Off: click a Status item to open its menu."
            checked: root.bar.statusMenusOnHover
            onToggled: Config.options.bar.statusMenusOnHover = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Panels push the bar"
            checked: root.bar.panelsPushBar
            onToggled: Config.options.bar.panelsPushBar = !checked
        }
        SliderRow {
            width: parent.width
            text: "Workspaces"
            icon: "grid_view"
            from: 1
            to: 10
            stepSize: 1
            value: root.bar.workspaceCount
            onMoved: v => Config.options.bar.workspaceCount = v
        }
        Column {
            width: parent.width
            spacing: Tokens.space2
            StyledText {
                style: "rowLabel"
                text: "Clock format"
            }
            SegmentedButtons {
                width: parent.width
                label: "Clock format"
                options: [{ value: "hh:mm", label: "24-hour" }, { value: "h:mm AP", label: "12-hour" }]
                current: root.bar.clockFormat
                onSelected: v => Config.options.bar.clockFormat = v
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "Spotlight"
        SwitchRow {
            width: parent.width
            text: "Media"
            checked: root.bar.spotlight.media
            onToggled: Config.options.bar.spotlight.media = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Timer and stopwatch"
            checked: root.bar.spotlight.timers
            onToggled: Config.options.bar.spotlight.timers = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Today's next event"
            checked: root.bar.spotlight.events
            onToggled: Config.options.bar.spotlight.events = !checked
        }
        Column {
            width: parent.width
            spacing: Tokens.space2
            StyledText {
                style: "rowLabel"
                text: "When nothing else is on"
            }
            SegmentedButtons {
                width: parent.width
                label: "When nothing else is on"
                options: [{ value: "weather", label: "Weather" }, { value: "system", label: "System" }, { value: "none", label: "Nothing" }]
                current: root.bar.spotlight.fallback
                onSelected: v => Config.options.bar.spotlight.fallback = v
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "Island"
        SwitchRow {
            width: parent.width
            text: "Island peek"
            description: "Point at the Island to see the current activity."
            checked: root.island.peek
            onToggled: Config.options.island.peek = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Hide the Island over apps"
            description: "It drops back in when you point at the top center."
            checked: Config.options.motion.islandHoverReveal
            onToggled: Config.options.motion.islandHoverReveal = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Detect screen recording"
            checked: root.island.detectRecording
            onToggled: Config.options.island.detectRecording = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Drop onto the Island to keep on the Shelf"
            checked: root.island.dropToShelf
            onToggled: Config.options.island.dropToShelf = !checked
        }
    }

    SettingsSection {
        width: parent.width
        title: "Activities"
        Repeater {
            model: [
                ["recording", "Screen recording"], ["screenShare", "Screen sharing"], ["micCamera", "Microphone and camera in use"],
                ["battery", "Low battery and charging"], ["bluetooth", "Bluetooth device connected"], ["timer", "Timer"],
                ["stopwatch", "Stopwatch"], ["media", "Media"], ["keepAwake", "Keep awake"],
                ["progress", "Progress from notifications"], ["event", "Upcoming event"], ["focus", "Focus session"],
                ["coral", "Coral"]
            ]
            SwitchRow {
                required property var modelData
                width: parent.width
                text: modelData[1]
                checked: Config.options.island.activities[modelData[0]]
                onToggled: Config.options.island.activities[modelData[0]] = !checked
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "Home"
        Row {
            spacing: Tokens.space2
            PillButton {
                height: Tokens.settingsButtonHeight
                accent: true
                text: "Edit home"
                onClicked: PanelState.open("editMode")
            }
            PillButton {
                height: Tokens.settingsButtonHeight
                neutralColor: Colors.surfaceContainerHighest
                text: "Reset widgets"
                onClicked: Home.reset(Monitors.focused)
            }
        }
        SwitchRow {
            width: parent.width
            text: "Wiggle while editing"
            checked: Config.options.home.wiggle
            onToggled: Config.options.home.wiggle = !checked
        }
        TextFieldRow {
            width: parent.width
            text: "Weather location"
            placeholder: "Automatic"
            value: Config.options.home.weatherLocation
            onCommitted: v => Config.options.home.weatherLocation = v.trim()
        }
        SegmentedButtons {
            width: parent.width
            label: "Temperature unit"
            options: [{ value: "c", label: "Celsius" }, { value: "f", label: "Fahrenheit" }]
            current: Config.options.home.temperatureUnit
            onSelected: v => Config.options.home.temperatureUnit = v
        }
    }

    SettingsSection {
        width: parent.width
        title: "Notifications"
        SwitchRow {
            width: parent.width
            text: "Do not disturb"
            checked: Notifications.dnd
            onToggled: Notifications.setDnd(!Notifications.dnd)
        }
        SwitchRow {
            width: parent.width
            text: "Volume and brightness OSD"
            checked: Config.options.osd.enabled
            onToggled: Config.options.osd.enabled = !checked
        }
        SwitchRow {
            width: parent.width
            text: "Toasts"
            checked: Config.options.toasts.enabled
            onToggled: Config.options.toasts.enabled = !checked
        }
    }

    SettingsSection {
        width: parent.width
        title: "Tools"
        SliderRow {
            width: parent.width
            text: "Clipboard history"
            icon: "content_paste"
            from: 50
            to: 1000
            stepSize: 50
            value: Config.options.clipboard.limit
            format: v => `${v} items`
            onMoved: v => Config.options.clipboard.limit = v
        }
        SwitchRow {
            width: parent.width
            text: "Search files"
            description: "Search looks for files in your home folder."
            checked: Config.options.search.files
            onToggled: Config.options.search.files = !checked
        }
        SliderRow {
            width: parent.width
            text: "Focus session"
            icon: "self_improvement"
            from: 5
            to: 90
            stepSize: 5
            value: Config.options.focus.focusMinutes
            format: v => `${v} min`
            onMoved: v => Config.options.focus.focusMinutes = v
        }
        SliderRow {
            width: parent.width
            text: "Break"
            icon: "coffee"
            from: 1
            to: 30
            stepSize: 1
            value: Config.options.focus.breakMinutes
            format: v => `${v} min`
            onMoved: v => Config.options.focus.breakMinutes = v
        }
        TextFieldRow {
            width: parent.width
            text: "Calendars"
            placeholder: ".ics files or links, separated by commas"
            value: Array.from(Config.options.calendar.sources).join(", ")
            onCommitted: v => Config.options.calendar.sources = v.split(",").map(s => s.trim()).filter(s => s !== "")
        }
    }
}
