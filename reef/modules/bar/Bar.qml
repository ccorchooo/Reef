import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services

// The bar (SURFACES.md → Bar): four separate cays along the bottom edge,
// space-2 apart and space-2 above the edge. Only the cays take input; the gaps
// between them click through to the desktop. Reserves cay-height + space-2.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        bottom: true
        left: true
        right: true
    }
    // Room above the cays for shadow-float.
    implicitHeight: Tokens.cayHeight + Tokens.space2 * 2
    exclusiveZone: Tokens.cayHeight + Tokens.space2
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-bar"

    // Keyboard access (Super+B): Tab between controls, Enter/Space to activate,
    // Escape, Super+B again or a click elsewhere to leave.
    property bool keyboardActive: false
    WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Actions
        function onFocusBarRequested() {
            if (Hyprland.focusedMonitor?.name !== root.modelData.name)
                return;
            root.keyboardActive = !root.keyboardActive;
            if (root.keyboardActive)
                focusFirst.restart();
        }
    }

    // Give the surface a moment to receive keyboard focus before moving into it.
    // The focus grab is armed only after that, or Hyprland clears it at once.
    Timer {
        id: focusFirst
        interval: 1
        onTriggered: {
            keys.nextItemInFocusChain(true)?.forceActiveFocus();
            armGrab.restart();
        }
    }

    Timer {
        id: armGrab
        interval: 150
        onTriggered: grab.armed = root.keyboardActive
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.keyboardActive
        onActivated: root.keyboardActive = false
    }

    // Clicking anywhere outside the bar gives the keyboard back.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.keyboardActive && armed
        property bool armed: false
        onActiveChanged: if (!root.keyboardActive) armed = false
        onCleared: root.keyboardActive = false
    }

    // Keep awake also holds on monitors without an Island.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.active
    }

    mask: Region {
        Region { item: dock }
        Region { item: navigator }
        Region { item: spotlight }
        Region { item: status }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.space2
        anchors.bottomMargin: Tokens.space2
        spacing: Tokens.space2

        Dock { id: dock }
        Navigator {
            id: navigator
            screenName: root.modelData.name
        }
        Spotlight { id: spotlight }
    }

    Status {
        id: status
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Tokens.space2
        anchors.bottomMargin: Tokens.space2
    }
}
