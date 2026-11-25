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
    // The surface is as tall as the screen so a cay can grow up out of it (a Status menu,
    // search) without resizing it: on a resize Hyprland sends the pointer a leave and no
    // enter until it moves, so a menu under a still pointer would close and reopen in a
    // loop. Only the cays take input, and the exclusive zone stays cay-height + space-2.
    implicitHeight: modelData.height
    exclusiveZone: Tokens.cayHeight + Tokens.space2
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-bar"

    // Keyboard access (Super+B): Tab between controls, Enter/Space to activate,
    // Escape, Super+B again or a click elsewhere to leave.
    property bool keyboardActive: false
    // Search (the Navigator cay grown into the search panel) takes the keyboard.
    readonly property bool searching: navigator.searching
    // Power actions (Ctrl+Alt+Delete): the Navigator re-forms into them over a heavy
    // scrim with the clock; the Dock and Spotlight step aside. They take the keyboard.
    readonly property bool power: navigator.power
    // A quick menu opened by hovering takes the keyboard only when clicked (OnDemand),
    // so it never steals typing from the focused app.
    WlrLayershell.keyboardFocus: keyboardActive || searching || power ? WlrKeyboardFocus.Exclusive
        : status.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onSearchingChanged: {
        if (searching)
            focusSearch.restart();
    }
    onPowerChanged: {
        if (power)
            focusPower.restart();
    }
    Timer {
        id: focusPower
        interval: 1
        onTriggered: navigator.focusPower()
    }
    // Give the surface a moment to receive keyboard focus before typing goes into it.
    Timer {
        id: focusSearch
        interval: 1
        onTriggered: navigator.focusSearch()
    }

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
    readonly property bool wantsGrab: keyboardActive || searching || power || status.holdOpen
    onWantsGrabChanged: wantsGrab ? armGrab.restart() : (grab.armed = false)

    Item {
        id: keys
        anchors.fill: parent
        focus: true
    }

    // Escape closes search or the Status cay's menu first, then leaves the bar.
    Shortcut {
        sequence: "Escape"
        enabled: root.keyboardActive || root.searching || root.power || status.menuOpen
        onActivated: root.searching || root.power || status.menuOpen ? PanelState.closeAll() : (root.keyboardActive = false)
    }

    // Clicking anywhere outside the bar gives the keyboard back and closes a menu.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.wantsGrab && armed
        property bool armed: false
        onCleared: {
            root.keyboardActive = false;
            if (status.menuOpen || root.searching || root.power)
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

    // A light scrim dims the desktop behind search (it takes no input: a click on it
    // reaches the window below and the focus grab closes search).
    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: scrimFade.value * Tokens.scrimLightOpacity
        visible: opacity > 0.001
        Spring {
            id: scrimFade
            spec: Motion.effectsSlow
            target: root.searching ? 1 : 0
        }
    }

    // ── power actions: heavy scrim, clock, time and date ────────
    Spring {
        id: powerFade
        spec: Motion.effectsSlow
        target: root.power ? 1 : 0
    }
    Spring {
        id: powerContent
        spec: Motion.effectsDefault
        target: root.power ? 1 : 0
    }
    Rectangle {
        anchors.fill: parent
        color: Colors.scrimHeavy
        opacity: powerFade.value
        visible: opacity > 0.001
    }
    // A click on the scrim closes the power actions.
    MouseArea {
        id: powerInput
        width: root.power ? root.width : 0
        height: root.power ? root.height : 0
        onClicked: PanelState.closeAll()
    }
    // Centered in the space above the bar.
    Row {
        x: Tokens.powerClockInset
        y: (root.height - root.exclusiveZone - height) / 2
        spacing: Tokens.powerClockGap
        opacity: powerContent.value
        visible: opacity > 0.01

        AnalogClock {
            anchors.verticalCenter: parent.verticalCenter
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.cayPaddingTight
            StyledText {
                style: "numeralLg"
                text: Time.time
            }
            StyledText {
                style: "bodyLg"
                text: Qt.formatDate(Time.now, "dddd, d MMMM") + (Battery.present ? " · battery " + Battery.percent : "")
            }
        }
    }

    mask: Region {
        Region { item: powerInput }
        Region { item: dock }
        Region { item: navigator }
        Region { item: spotlight }
        Region { item: status }
    }

    // The Dock and Spotlight step aside for the power actions; the Navigator slides into
    // the Dock's place.
    Spring {
        id: powerShift
        spec: Motion.spatialDefault
        target: root.power ? dock.width + Tokens.space2 : 0
    }
    Spring {
        id: asideFade
        spec: Motion.effectsFast
        target: root.power ? 0 : 1
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.space2 + leftInset.value - powerShift.value
        anchors.bottomMargin: Tokens.space2
        spacing: Tokens.space2

        // Bottom-aligned: the Navigator cay grows up into search.
        Dock {
            id: dock
            anchors.bottom: parent.bottom
            opacity: asideFade.value
            enabled: !root.power
        }
        Navigator {
            id: navigator
            anchors.bottom: parent.bottom
            screenName: root.modelData.name
        }
        Spotlight {
            id: spotlight
            anchors.bottom: parent.bottom
            opacity: asideFade.value
            enabled: !root.power
        }
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
