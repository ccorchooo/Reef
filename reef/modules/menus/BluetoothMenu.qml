import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Bluetooth quick menu: switch, devices (connected ones on primary-container),
// Bluetooth settings. Scans for new devices while open.
Column {
    id: root

    property bool active: false
    // Inside Settings → Bluetooth the button opens the advanced tools instead of Settings.
    property bool inSettings: false

    width: Tokens.menuWifiWidth - Tokens.space4 * 2
    spacing: Tokens.space2_5

    onActiveChanged: BluetoothState.scan(active)
    Component.onCompleted: BluetoothState.scan(active)
    Component.onDestruction: BluetoothState.scan(false)

    Row {
        width: parent.width
        spacing: Tokens.space3
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - toggle.width - parent.spacing
            style: "cardTitle"
            text: "Bluetooth"
        }
        Switch {
            id: toggle
            visible: BluetoothState.available
            label: "Bluetooth"
            checked: BluetoothState.enabled
            onToggled: BluetoothState.toggle()
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.spaceHalf

        Repeater {
            model: BluetoothState.enabled ? BluetoothState.devices.slice(0, 8) : []
            ListRow {
                required property var modelData
                width: root.width
                icon: BluetoothState.icon(modelData)
                title: modelData.name || modelData.address
                subtitle: modelData.connected ? (modelData.batteryAvailable ? `Connected · ${Math.round((modelData.battery > 1 ? modelData.battery / 100 : modelData.battery) * 100)}%` : "Connected")
                    : modelData.pairing ? "Pairing…" : modelData.paired ? "" : "New"
                selected: modelData.connected
                trailingIcon: modelData.connected ? "check" : ""
                onClicked: BluetoothState.activate(modelData)
            }
        }

        StyledText {
            visible: !BluetoothState.available || !BluetoothState.enabled || BluetoothState.devices.length === 0
            width: parent.width
            height: Tokens.listRowHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: "bodyMd"
            color: Colors.on.surfaceVariant
            text: !BluetoothState.available ? "No Bluetooth adapter" : !BluetoothState.enabled ? "Bluetooth is off" : "Looking for devices…"
        }
    }

    MenuButton {
        width: parent.width
        text: root.inSettings ? "Advanced Bluetooth settings" : "Bluetooth settings"
        onClicked: {
            PanelState.closeAll();
            if (root.inSettings)
                Quickshell.execDetached(["sh", "-c", "blueman-manager || $TERMINAL -e bluetoothctl || kitty bluetoothctl || foot bluetoothctl"]);
            else
                Actions.openSettings("bluetooth");
        }
    }
}
