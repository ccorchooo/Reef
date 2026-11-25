import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.components

// Settings → About: the Reef lockup (DESIGN.md §7: the mark plus the wordmark at 0.9× its
// height, half its width apart), then the system and where the settings live.
Column {
    id: root

    spacing: Tokens.settingsGap

    property string versions: ""
    Process {
        running: true
        command: ["sh", "-c", "qs --version 2>/dev/null | head -1 | cut -d'(' -f1; hyprctl version 2>/dev/null | head -1 | cut -d' ' -f1-2"]
        stdout: StdioCollector {
            onStreamFinished: root.versions = text.trim()
        }
    }

    Row {
        spacing: Tokens.greeterLogo / 2
        Logo {
            anchors.verticalCenter: parent.verticalCenter
            size: Tokens.greeterLogo
            color: Colors.primary
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            style: "greeterWordmark"
            text: "Reef"
        }
    }

    SettingsSection {
        width: parent.width
        Repeater {
            model: [
                ["System", OsInfo.prettyName],
                ["Shell", root.versions.split("\n")[0] ?? ""],
                ["Compositor", root.versions.split("\n")[1] ?? ""],
                ["Settings file", Config.path]
            ]
            Item {
                required property var modelData
                width: parent.width
                height: value.implicitHeight
                visible: modelData[1] !== ""
                StyledText {
                    style: "rowLabel"
                    color: Colors.on.surfaceVariant
                    text: modelData[0]
                }
                StyledText {
                    id: value
                    anchors.right: parent.right
                    width: Math.min(implicitWidth, parent.width * 2 / 3)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                    style: "rowLabel"
                    text: modelData[1]
                }
            }
        }
        PillButton {
            height: Tokens.settingsButtonHeight
            neutralColor: Colors.surfaceContainerHighest
            text: "Open the settings folder"
            onClicked: Quickshell.execDetached(["xdg-open", Config.dir])
        }
    }
}
