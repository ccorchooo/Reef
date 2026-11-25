import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Keyboard & shortcuts: the keyboard layout and Reef's shortcuts (bound in
// hypr/reef.lua).
Column {
    id: root

    spacing: Tokens.settingsGap

    SettingsSection {
        width: parent.width
        title: "Keyboard layout"
        StyledText {
            style: "rowLabel"
            text: Keyboard.layout || "Unknown"
        }
    }

    SettingsSection {
        width: parent.width
        title: "Shortcuts"
        Repeater {
            model: [
                ["Super", "Search"],
                ["Hold Super", "Show the workspaces in the bar"],
                ["Super + V", "Clipboard"],
                ["Super + .", "Emoji"],
                ["Super + C", "Coral"],
                ["Super + N", "Control center"],
                ["Super + Tab", "Workspace overview"],
                ["Alt + Tab", "Switch windows"],
                ["Super + E", "Edit mode"],
                ["Super + L", "Lock"],
                ["Ctrl + Alt + Delete", "Power actions"],
                ["Super + B", "Move into the bar"],
                ["Super + I", "Open the Island"],
                ["Super + Shift + I", "Swap the Island's activities"]
            ]
            Item {
                required property var modelData
                width: parent.width
                height: Tokens.chipHeight
                Accessible.role: Accessible.StaticText
                Accessible.name: `${modelData[1]}: ${modelData[0]}`

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    style: "rowLabel"
                    text: modelData[1]
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: keys.implicitWidth + Tokens.space3 * 2
                    height: Tokens.chipHeight
                    radius: Tokens.radiusSm
                    color: Colors.surfaceContainerHighest
                    StyledText {
                        id: keys
                        anchors.centerIn: parent
                        style: "monoMd"
                        text: modelData[0]
                    }
                }
            }
        }
    }
}
