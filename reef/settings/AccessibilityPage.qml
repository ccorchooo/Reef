import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Accessibility: motion and scale.
Column {
    id: root

    spacing: Tokens.settingsGap

    SettingsSection {
        width: parent.width
        title: "Motion"
        SwitchRow {
            width: parent.width
            text: "Reduce motion"
            description: "Things fade instead of moving, and nothing wiggles."
            checked: Config.options.motion.reduceMotion
            onToggled: Config.options.motion.reduceMotion = !checked
        }
        SliderRow {
            width: parent.width
            text: "Animation speed"
            icon: "speed"
            from: 0.5
            to: 2
            stepSize: 0.25
            value: Config.options.motion.speed
            format: v => `${v}×`
            onMoved: v => Config.options.motion.speed = v
        }
    }

    SettingsSection {
        width: parent.width
        title: "Zoom"
        SegmentedButtons {
            width: parent.width
            label: "Zoom"
            options: [0.75, 0.9, 1, 1.1, 1.25, 1.5].map(z => ({ value: String(z), label: Math.round(z * 100) + "%" }))
            current: String(Config.options.scale.zoom)
            onSelected: v => Config.options.scale.zoom = Number(v)
        }
    }

    SettingsSection {
        width: parent.width
        title: "Scale"
        SliderRow {
            width: parent.width
            text: "Text size"
            icon: "format_size"
            from: 0.8
            to: 1.5
            stepSize: 0.05
            value: Config.options.scale.text
            format: v => `${Math.round(v * 100)}%`
            onMoved: v => Config.options.scale.text = v
        }
        SliderRow {
            width: parent.width
            text: "Spacing"
            icon: "density_medium"
            from: 0.75
            to: 1.5
            stepSize: 0.05
            value: Config.options.scale.spacing
            format: v => `${Math.round(v * 100)}%`
            onMoved: v => Config.options.scale.spacing = v
        }
        SliderRow {
            width: parent.width
            text: "Corner roundness"
            icon: "rounded_corner"
            from: 0
            to: 1.5
            stepSize: 0.05
            value: Config.options.scale.corners
            format: v => `${Math.round(v * 100)}%`
            onMoved: v => Config.options.scale.corners = v
        }
    }
}
