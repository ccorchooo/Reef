import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Widgets: how the home widgets look. Clock: a live preview, then its shape,
// numbers, face color, ticks and second hand (home.clock).
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var clock: Config.options.home.clock
    readonly property var shapes: [
        { value: "circle", label: "Circle" },
        { value: "squircle", label: "Squircle" },
        { value: "cookie4", label: "Cookie" },
        { value: "cookie9", label: "Scallop" },
        { value: "cookie12", label: "Gear" },
        { value: "sunny", label: "Sunny" },
        { value: "flower", label: "Flower" },
        { value: "clover8", label: "Clover" },
        { value: "pentagon", label: "Pentagon" }
    ]

    // ── clock ──
    Rectangle {
        width: parent.width
        height: clockRow.implicitHeight + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerHigh

        Row {
            id: clockRow
            x: Tokens.space4
            y: Tokens.space4
            width: parent.width - Tokens.space4 * 2
            spacing: Tokens.space5

            AnalogClock {
                anchors.verticalCenter: parent.verticalCenter
                size: Tokens.settingsClockPreview
                shape: root.clock.shape
                numbers: root.clock.numbers
                ticks: root.clock.ticks
                seconds: root.clock.seconds
                tone: root.clock.color
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.settingsClockPreview - parent.spacing
                spacing: Tokens.space4

                StyledText {
                    style: "settingsSection"
                    text: "Clock"
                    Accessible.role: Accessible.Heading
                }
                SwitchRow {
                    width: parent.width
                    text: "Hour ticks"
                    checked: root.clock.ticks
                    onToggled: Config.options.home.clock.ticks = !root.clock.ticks
                }
                SwitchRow {
                    width: parent.width
                    text: "Second hand"
                    checked: root.clock.seconds
                    onToggled: Config.options.home.clock.seconds = !root.clock.seconds
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            style: "settingsSection"
            text: "Numbers"
        }
        SegmentedButtons {
            width: parent.width
            label: "Clock numbers"
            options: [{ value: "none", label: "None" }, { value: "quarters", label: "12 3 6 9" }, { value: "all", label: "All" }, { value: "hour", label: "Big hour" }]
            current: root.clock.numbers
            onSelected: v => Config.options.home.clock.numbers = v
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            style: "settingsSection"
            text: "Face color"
        }
        SegmentedButtons {
            width: parent.width
            label: "Clock face color"
            options: [{ value: "surface", label: "Surface" }, { value: "primary", label: "Primary" }, { value: "secondary", label: "Secondary" }, { value: "tertiary", label: "Tertiary" }]
            current: root.clock.color
            onSelected: v => Config.options.home.clock.color = v
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            style: "settingsSection"
            text: "Shape"
        }
        Flow {
            width: parent.width
            spacing: Tokens.space2
            Accessible.role: Accessible.Grouping
            Accessible.name: "Clock shape"

            Repeater {
                model: root.shapes
                OptionCard {
                    id: shapeCard
                    required property var modelData
                    width: Tokens.settingsPaletteCard
                    text: modelData.label
                    selected: root.clock.shape === modelData.value
                    onClicked: Config.options.home.clock.shape = modelData.value
                    ShapeItem {
                        anchors.centerIn: parent
                        width: Tokens.settingsOptionGlyph
                        height: Tokens.settingsOptionGlyph
                        radii: Shapes.sample(shapeCard.modelData.value, width, height)
                        color: shapeCard.selected ? Colors.primary : Colors.on.surfaceVariant
                    }
                }
            }
        }
    }
}
