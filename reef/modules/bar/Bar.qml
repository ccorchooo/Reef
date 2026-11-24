import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// The bar (SURFACES.md → Bar): four separate cays along the bottom edge,
// space-2 apart and space-2 above the edge. Only the cays take input; the gaps
// between them click through to the desktop. Reserves cay-height + space-2.
// A Tide panel pushes the bar aside instead of covering it: the cays slide in from the
// panel's edge by the panel's width, with the panel's own spring (spatial-default).
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        bottom: true
        left: true
        right: true
    }
    // The surface is as tall as the screen so the Status cay can grow up into a quick
    // menu without resizing it (a resize makes the compositor re-send pointer enter and
    // leave). Only the cays take input, and the exclusive zone stays cay-height + space-2.
    implicitHeight: modelData.height
    exclusiveZone: Tokens.cayHeight + Tokens.space2
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-bar"

    // Keyboard access (Super+B): Tab between controls, Enter/Space to activate,
    // Escape, Super+B again or a click elsewhere to leave.
    property bool keyboardActive: false
    // A quick menu opened by hovering takes the keyboard only when clicked (OnDemand),
    // so it never steals typing from the focused app.
    WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive
        : status.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
        onTriggered: grab.armed = root.wantsGrab
    }

    // Typing in a menu (a Wi-Fi password) holds it open until a click elsewhere.
    readonly property bool wantsGrab: keyboardActive || status.holdOpen
    onWantsGrabChanged: wantsGrab ? armGrab.restart() : (grab.armed = false)

    Item {
        id: keys
        anchors.fill: parent
        focus: true
    }

    // Escape closes the Status cay's menu first, then leaves the bar.
    Shortcut {
        sequence: "Escape"
        enabled: root.keyboardActive || status.menuOpen
        onActivated: status.menuOpen ? PanelState.closeAll() : (root.keyboardActive = false)
    }

    // Clicking anywhere outside the bar gives the keyboard back and closes a menu.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.wantsGrab && armed
        property bool armed: false
        onCleared: {
            root.keyboardActive = false;
            if (status.menuOpen)
                PanelState.closeAll();
        }
    }

    // ── Tide panels push the bar ───────────────────────────────
    readonly property bool pushable: Config.options.bar.panelsPushBar && PanelState.screenName === modelData.name
    Spring {
        id: rightInset
        spec: Motion.spatialDefault
        target: root.pushable && PanelState.panel === "controlCenter" ? Tokens.panelWidth : 0
    }
    Spring {
        id: leftInset
        spec: Motion.spatialDefault
        target: root.pushable && PanelState.panel === "editMode" ? Tokens.editPanelWidth : 0
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
        anchors.leftMargin: Tokens.space2 + leftInset.value
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
        screenName: root.modelData.name
        keyboardActive: root.keyboardActive
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Tokens.space2 + rightInset.value
        anchors.bottomMargin: Tokens.space2
    }
}
