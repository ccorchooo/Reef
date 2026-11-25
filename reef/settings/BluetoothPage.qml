import QtQuick
import qs.theme
import qs.components
import qs.modules.menus

// Settings → Bluetooth: the Bluetooth quick menu (scanning while shown), with a button to
// the advanced tools.
Column {
    spacing: Tokens.settingsGap

    SettingsSection {
        width: parent.width
        BluetoothMenu {
            width: parent.width
            active: true
            inSettings: true
        }
    }
}
