import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.lock

// Settings → Lock screen: the Pearl (a live preview, then what it shows, its color and
// shape), what else the lock screen shows, and when it locks (lock.*).
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var lock: Config.options.lock
    readonly property var pearl: Config.options.lock.pearl

    // ── the Pearl ──
    Rectangle {
        width: parent.width
        height: pearlRow.implicitHeight + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerHigh

        Row {
            id: pearlRow
            x: Tokens.space4
            y: Tokens.space4
            width: parent.width - Tokens.space4 * 2
            spacing: Tokens.space5

            // On the wallpaper, as on the lock screen, with room for the progress ring.
            ShapeImage {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.settingsPearlPreview + (Tokens.pearlRingGap + Tokens.pearlRingWidth + Tokens.space2) * 2
                height: width
                shape: "squircle"
                source: Config.options.look.wallpaper !== "" ? "file://" + Config.options.look.wallpaper : ""
                color: Colors.surfaceContainerHighest
                Pearl {
                    anchors.centerIn: parent
                    width: Tokens.settingsPearlPreview
                    height: Tokens.settingsPearlPreview
                    activity: root.lock.activity
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.settingsPearlPreview - (Tokens.pearlRingGap + Tokens.pearlRingWidth + Tokens.space2) * 2 - parent.spacing
                spacing: Tokens.space4

                StyledText {
                    style: "settingsSection"
                    text: "Pearl"
                    Accessible.role: Accessible.Heading
                }
                SwitchRow {
                    width: parent.width
                    text: "Show the current activity"
                    description: "Music plays as a small player."
                    checked: root.lock.activity
                    onToggled: Config.options.lock.activity = !root.lock.activity
                }
                SwitchRow {
                    width: parent.width
                    text: "Date"
                    checked: root.pearl.date
                    onToggled: Config.options.lock.pearl.date = !root.pearl.date
                }
                SwitchRow {
                    width: parent.width
                    text: "Hop on the minute"
                    checked: root.pearl.hop
                    onToggled: Config.options.lock.pearl.hop = !root.pearl.hop
                }
                PillButton {
                    accent: true
                    text: "Preview lock screen"
                    onClicked: Lock.showPreview(true)
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            style: "settingsSection"
            text: "Face"
        }
        SegmentedButtons {
            width: parent.width
            label: "Pearl face"
            options: [{ value: "digital", label: "Clock" }, { value: "analog", label: "Analog" }, { value: "stats", label: "System" }]
            current: root.pearl.face
            onSelected: v => Config.options.lock.pearl.face = v
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            style: "settingsSection"
            text: "Color"
        }
        SegmentedButtons {
            width: parent.width
            label: "Pearl color"
            options: [{ value: "island", label: "Black" }, { value: "primary", label: "Primary" }, { value: "secondary", label: "Secondary" }, { value: "tertiary", label: "Tertiary" }]
            current: root.pearl.color
            onSelected: v => Config.options.lock.pearl.color = v
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
            Accessible.name: "Pearl shape"

            Repeater {
                model: Shapes.choices
                OptionCard {
                    id: shapeCard
                    required property var modelData
                    width: Tokens.settingsPaletteCard
                    text: modelData.label
                    selected: root.pearl.shape === modelData.value
                    onClicked: Config.options.lock.pearl.shape = modelData.value
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

    SettingsSection {
        width: parent.width
        title: "Lock screen"
        SwitchRow {
            width: parent.width
            text: "Status"
            description: "Network, battery and keyboard layout."
            checked: root.lock.status
            onToggled: Config.options.lock.status = !root.lock.status
        }
        SwitchRow {
            width: parent.width
            text: "Power buttons"
            description: "Sleep, Power off and Restart."
            checked: root.lock.powerButtons
            onToggled: Config.options.lock.powerButtons = !root.lock.powerButtons
        }
    }

    SettingsSection {
        width: parent.width
        title: "Locking"
        SwitchRow {
            width: parent.width
            text: "Lock when the lid closes"
            checked: root.lock.onLidClose
            onToggled: Config.options.lock.onLidClose = !root.lock.onLidClose
        }
        SwitchRow {
            width: parent.width
            text: "Lock before sleep"
            checked: Config.options.session.lockBeforeSleep
            onToggled: Config.options.session.lockBeforeSleep = !checked
        }
    }
}
