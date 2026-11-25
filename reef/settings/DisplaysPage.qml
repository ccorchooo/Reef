import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Settings → Displays: per monitor, which of Reef's surfaces it gets and where its bar
// sits; then Night light.
Column {
    id: root

    spacing: Tokens.settingsGap

    Repeater {
        model: Quickshell.screens

        SettingsSection {
            id: screenSection
            required property var modelData
            readonly property string name: modelData.name
            readonly property var m: Config.monitor(name)

            width: root.width
            title: [modelData.name, modelData.model, `${modelData.width} × ${modelData.height}`].filter(s => s).join(" · ")

            SwitchRow {
                width: parent.width
                text: "Bar"
                checked: screenSection.m.showBar
                onToggled: Config.setMonitor(screenSection.name, "showBar", !checked)
            }
            Column {
                width: parent.width
                spacing: Tokens.space2
                visible: screenSection.m.showBar
                StyledText {
                    style: "rowLabel"
                    text: "Bar position"
                }
                SegmentedButtons {
                    width: parent.width
                    label: "Bar position"
                    options: [{ value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }]
                    current: screenSection.m.barPosition
                    onSelected: v => Config.setMonitor(screenSection.name, "barPosition", v)
                }
            }
            SwitchRow {
                width: parent.width
                text: "Island"
                checked: screenSection.m.showIsland
                onToggled: Config.setMonitor(screenSection.name, "showIsland", !checked)
            }
            SwitchRow {
                width: parent.width
                text: "Home widgets"
                checked: screenSection.m.showWidgets
                onToggled: Config.setMonitor(screenSection.name, "showWidgets", !checked)
            }
            SwitchRow {
                width: parent.width
                text: "Rounded screen corners"
                checked: screenSection.m.showCorners
                onToggled: Config.setMonitor(screenSection.name, "showCorners", !checked)
            }
        }
    }

    SettingsSection {
        width: parent.width
        title: "Night light"
        SwitchRow {
            width: parent.width
            text: "Night light"
            checked: NightLight.enabled
            onToggled: NightLight.toggle()
        }
        SliderRow {
            width: parent.width
            text: "Warmth"
            icon: "nightlight"
            // Warmer is lower kelvin: the slider runs from cool to warm.
            from: -6500
            to: -2500
            stepSize: 100
            value: -Config.options.nightLight.temperature
            format: v => `${-v} K`
            onMoved: v => Config.options.nightLight.temperature = -v
        }
    }
}
