import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Wi-Fi quick menu (screens/QuickMenus): switch, networks (connected one on
// primary-container), and Network settings. A secured network that isn't saved
// opens a password field under its row.
Column {
    id: root

    property bool active: false
    property var asking: null       // network waiting for a password

    width: Tokens.menuWifiWidth - Tokens.space4 * 2
    spacing: Tokens.space2_5

    onActiveChanged: Network.scan(active)
    Component.onCompleted: Network.scan(active)
    Component.onDestruction: Network.scan(false)

    Row {
        width: parent.width
        spacing: Tokens.space3
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - toggle.width - parent.spacing
            style: "cardTitle"
            text: "Wi-Fi"
        }
        Switch {
            id: toggle
            label: "Wi-Fi"
            checked: Network.wifiEnabled
            onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.spaceHalf
        visible: Network.wifiEnabled

        Repeater {
            model: ScriptModel {
                values: Network.networks.slice(0, 8)
                objectProp: "name"
            }

            ListRow {
                id: row
                required property var modelData
                width: root.width
                icon: Network.signalIcon(modelData)
                title: modelData.name
                subtitle: modelData.connected ? "Connected" : modelData.stateChanging ? "Connecting…" : ""
                selected: modelData.connected
                trailingIcon: modelData.connected ? "check" : Network.secured(modelData) && !modelData.known ? "lock" : ""
                onClicked: {
                    if (!modelData.connected && !modelData.known && Network.secured(modelData))
                        root.asking = root.asking === modelData ? null : modelData;
                    else {
                        root.asking = null;
                        Network.connect(modelData);
                    }
                }

                Rectangle {
                    visible: root.asking === row.modelData
                    width: parent.width
                    height: visible ? Tokens.replyFieldHeight : 0
                    radius: height / 2
                    color: Colors.surfaceContainerLowest
                    border.width: password.activeFocus ? 2 : 1
                    border.color: password.activeFocus ? Colors.primary : Colors.outlineVariant

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space4
                        anchors.rightMargin: Tokens.space4
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Colors.on.surface
                        font: Type.font("bodyMd")
                        clip: true
                        focus: parent.visible
                        Accessible.role: Accessible.EditableText
                        Accessible.name: `Password for ${row.modelData.name}`
                        onVisibleChanged: if (visible) forceActiveFocus()
                        onAccepted: {
                            Network.connect(row.modelData, text);
                            text = "";
                            root.asking = null;
                        }
                    }
                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.space4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text === ""
                        style: "bodyMd"
                        color: Colors.on.surfaceVariant
                        text: "Password"
                    }
                }
            }
        }

        StyledText {
            visible: Network.networks.length === 0
            width: parent.width
            height: Tokens.listRowHeight
            horizontalAlignment: Text.AlignHCenter
            style: "bodyMd"
            color: Colors.on.surfaceVariant
            text: Network.wired ? "Connected by cable" : "Looking for networks…"
        }
    }

    MenuButton {
        width: parent.width
        text: "Network settings"
        onClicked: {
            PanelState.closeAll();
            Quickshell.execDetached(["sh", "-c", "nm-connection-editor || $TERMINAL -e nmtui || kitty nmtui || foot nmtui"]);
        }
    }
}
