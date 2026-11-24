import QtQuick

// The body of one quick menu, by name. Shared by its two homes: the Status cay that
// grows into it and the card floating inside the control center (PanelState).
//
//   MenuContent { menu: "wifi"; live: open }
Loader {
    id: root

    property string menu: ""
    // While true, menus that scan (Wi-Fi, Bluetooth) keep scanning.
    property bool live: false
    // The menu is busy (typing a Wi-Fi password): don't close it on hover-out.
    readonly property bool holdOpen: item?.holdOpen ?? false
    readonly property string title: ({ calendar: "Calendar", wifi: "Wi-Fi", bluetooth: "Bluetooth", audio: "Audio output" })[menu] ?? ""

    sourceComponent: ({ calendar: calendarMenu, wifi: wifiMenu, bluetooth: bluetoothMenu, audio: audioMenu })[menu] ?? null

    Component { id: calendarMenu; CalendarMenu {} }
    Component { id: wifiMenu; WifiMenu { active: root.live } }
    Component { id: bluetoothMenu; BluetoothMenu { active: root.live } }
    Component { id: audioMenu; AudioMenu {} }
}
