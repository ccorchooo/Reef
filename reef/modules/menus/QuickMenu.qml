import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// Quick menus (SURFACES.md → Quick menus; screens/QuickMenus): surface-container cards
// with radius-xl floating above the Status cay. They grow up out of it (spatial-default)
// and fade (effects-default). One at a time; Escape or a click elsewhere closes.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        bottom: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-menu"

    readonly property string menu: PanelState.screenName === modelData.name ? PanelState.menu : ""
    readonly property bool open: menu !== ""
    // The last menu shown, so it can animate out.
    property string shown: ""
    onMenuChanged: if (menu !== "") shown = menu

    readonly property real barSpace: Config.monitor(modelData.name).showBar ? Tokens.cayHeight + Tokens.space2 * 2 : Tokens.space2
    readonly property real shadowRoom: Colors.shadowMenu.blur + Colors.shadowMenu.y
    implicitWidth: card.width + Tokens.space2 + shadowRoom
    implicitHeight: card.height + barSpace + shadowRoom

    visible: open || grow.value > 0.01
    mask: Region { item: card }

    Spring {
        id: grow
        spec: Motion.spatialDefault
        target: root.open ? 1 : 0
    }
    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.open ? 1 : 0
    }

    // ── keyboard and dismissal ──
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenChanged: {
        if (open)
            focusFirst.restart();
        else
            grab.armed = false;
    }
    Timer {
        id: focusFirst
        interval: 1
        onTriggered: {
            keys.forceActiveFocus();
            armGrab.restart();
        }
    }
    Timer {
        id: armGrab
        interval: 150
        onTriggered: grab.armed = root.open
    }
    Item {
        id: keys
        focus: true
        Keys.onTabPressed: keys.nextItemInFocusChain(true)?.forceActiveFocus()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: PanelState.closeAll()
    }
    HyprlandFocusGrab {
        id: grab
        property bool armed: false
        windows: [root]
        active: root.open && armed
        onCleared: if (PanelState.menu !== "") PanelState.closeAll()
    }

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        offset.x: Colors.shadowMenu.x
        offset.y: Colors.shadowMenu.y
        blur: Colors.shadowMenu.blur
        color: Colors.shadowMenu.color
        opacity: card.opacity
        scale: card.scale
        transformOrigin: Item.BottomRight
    }

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.barSpace
        width: content.width + Tokens.space4 * 2
        height: content.height + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainer
        opacity: fade.value
        scale: 0.85 + 0.15 * grow.value
        transformOrigin: Item.BottomRight

        Accessible.role: Accessible.Dialog
        Accessible.name: ({ calendar: "Calendar", wifi: "Wi-Fi", bluetooth: "Bluetooth", audio: "Audio output" })[root.shown] ?? ""

        Loader {
            id: content
            x: Tokens.space4
            y: Tokens.space4
            sourceComponent: ({ calendar: calendarMenu, wifi: wifiMenu, bluetooth: bluetoothMenu, audio: audioMenu })[root.shown] ?? null
        }
    }

    Component { id: calendarMenu; CalendarMenu {} }
    Component { id: wifiMenu; WifiMenu { active: root.open } }
    Component { id: bluetoothMenu; BluetoothMenu { active: root.open } }
    Component { id: audioMenu; AudioMenu {} }
}
