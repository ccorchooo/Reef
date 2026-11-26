import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules.lock
import qs.modules.island
import qs.modules

// The bar (SURFACES.md → Bar): four separate cays along the bottom edge,
// space-2 apart and space-2 above the edge. Only the cays take input; the gaps
// between them click through to the desktop. Reserves cay-height + space-2.
// A Tide panel pushes the bar aside instead of covering it: the cays slide in from the
// panel's edge by the panel's width, with the panel's own spring (spatial-default).
// Bar on the left (per monitor, screens/BarLeft): the cays stack down the left edge
// space-2 from it, the Status cay at the bottom, and it reserves cay-height + space-2
// on the left instead.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    readonly property bool barLeft: Config.monitor(modelData.name).barPosition === "left"

    anchors {
        top: barLeft
        bottom: true
        left: true
        right: !barLeft
    }
    // The surface is as tall as the screen so a cay can grow up out of it (a Status menu,
    // search) without resizing it: on a resize Hyprland sends the pointer a leave and no
    // enter until it moves, so a menu under a still pointer would close and reopen in a
    // loop. Only the cays take input, and the exclusive zone stays cay-height + space-2.
    implicitHeight: modelData.height
    implicitWidth: modelData.width
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
    // scrim with the Pearl; the Dock and Spotlight step aside. They take the keyboard.
    readonly property bool power: navigator.power
    // A quick menu opened by hovering takes the keyboard only when clicked (OnDemand),
    // so it never steals typing from the focused app.
    // The app menu (right-click a Dock tile or an app in search) takes it while open.
    WlrLayershell.keyboardFocus: keyboardActive || searching || power || appMenu.open ? WlrKeyboardFocus.Exclusive
        : status.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onSearchingChanged: {
        if (searching)
            focusSearch.restart();
    }
    onPowerChanged: {
        if (power) {
            // The Pearl grows out of this monitor's Island (MOTION.md → Island → Pearl).
            pearlFrom = IslandState.bodyRect(modelData.name, width);
            pearlHandedOff = false;
            IslandState.pearlScreen = modelData.name;
            pearlForm.target = 1;
            focusPower.restart();
        } else {
            pearlForm.target = 0;
        }
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
    readonly property bool wantsGrab: keyboardActive || searching || power || status.holdOpen || appMenu.open
    onWantsGrabChanged: wantsGrab ? armGrab.restart() : (grab.armed = false)

    Item {
        id: keys
        anchors.fill: parent
        focus: true
    }

    // Escape closes search or the Status cay's menu first, then leaves the bar.
    Shortcut {
        sequence: "Escape"
        enabled: root.keyboardActive || root.searching || root.power || status.menuOpen || appMenu.open
        onActivated: appMenu.open ? appMenu.hide()
            : root.searching || root.power || status.menuOpen ? PanelState.closeAll() : (root.keyboardActive = false)
    }

    // Clicking anywhere outside the bar gives the keyboard back and closes a menu.
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.wantsGrab && armed
        property bool armed: false
        onCleared: {
            root.keyboardActive = false;
            appMenu.hide();
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

    // ── behind the bar while the overview is open ──────────────
    // The overview blurs the screen behind it and dims it lightly; the bar's strip gets the
    // same compositor blur and scrim, so the whole background reads as one and the cays
    // stay in front.
    readonly property bool overviewOpen: PanelState.panel === "overview" && PanelState.screenName === modelData.name
    Spring {
        id: overviewFade
        spec: Motion.effectsSlow
        target: root.overviewOpen ? 1 : 0
    }
    Item {
        id: overviewStrip
        y: root.barLeft ? 0 : root.height - root.exclusiveZone
        width: root.barLeft ? root.exclusiveZone : root.width
        height: root.barLeft ? root.height : root.exclusiveZone
        opacity: overviewFade.value
        visible: opacity > 0.001

        Rectangle {
            anchors.fill: parent
            color: Colors.scrim
            opacity: Tokens.scrimLightOpacity
        }
    }
    Item {
        id: overviewBlur
        x: overviewStrip.x
        y: overviewStrip.y
        width: root.overviewOpen ? overviewStrip.width : 0
        height: root.overviewOpen ? overviewStrip.height : 0
    }

    // ── power actions: heavy scrim, the Pearl, time and date ────────
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
    // The scheme-tinted heavy scrim over a blur of the desktop (the compositor blurs what's
    // behind the bar's surface while the power actions are open).
    Rectangle {
        anchors.fill: parent
        color: Colors.scrimHeavy
        opacity: powerFade.value
        visible: opacity > 0.001
    }
    Item {
        id: powerBlur
        width: root.power ? root.width : 0
        height: root.power ? root.height : 0
    }
    BackgroundEffect.blurRegion: Region {
        Region { item: powerBlur }
        Region { item: overviewBlur }
    }
    // A click on the scrim closes the power actions.
    MouseArea {
        id: powerInput
        width: root.power ? root.width : 0
        height: root.power ? root.height : 0
        onClicked: PanelState.closeAll()
    }
    // Centered in the space above (or beside) the bar.
    Row {
        id: powerRow
        x: Tokens.powerClockInset
        y: (root.height - (root.barLeft ? 0 : root.exclusiveZone) - height) / 2
        spacing: Tokens.powerClockGap
        opacity: powerContent.value
        visible: opacity > 0.01

        // Where the Pearl lands (it's drawn below, so it can fly in from the Island).
        Item {
            id: pearlSlot
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.powerClockSize
            height: Tokens.powerClockSize
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

    // ── the Pearl, out of the Island ────────────────────────────
    // Where the clock was: its face, or the Island's main activity. 0 = the Island's body,
    // 1 = in its slot. Opening drops it there on spatial-bouncy as the pill rounds into the
    // Pearl; closing folds it back into the Island (spatial-default), which then returns.
    // Locking from here hands it to the lock screen, which carries on from where it is.
    property var pearlFrom: ({ x: 0, y: 0, w: 0, h: 0 })
    property bool pearlHandedOff: false
    Spring {
        id: pearlForm
        spec: root.power ? Motion.spatialBouncy : Motion.spatialDefault
        target: 0
    }
    Spring {
        id: pearlContent
        spec: Motion.effectsDefault
        target: pearlForm.target === 1 && pearlForm.value > 0.75 ? 1 : 0
    }
    // Out until it has folded back; then the Island shows again.
    readonly property bool pearlOut: power || pearlForm.running || pearlForm.value > 0.001
    onPearlOutChanged: {
        if (!pearlOut && IslandState.pearlScreen === modelData.name)
            IslandState.pearlScreen = "";
    }
    Connections {
        target: Lock
        function onAboutToLock() {
            if (!powerPearl.visible)
                return;
            Lock.handoff = { screen: root.modelData.name, x: powerPearl.x, y: powerPearl.y, w: powerPearl.width, h: powerPearl.height };
            root.pearlHandedOff = true;
        }
    }

    Pearl {
        id: powerPearl

        readonly property real t: pearlForm.value
        readonly property real placeX: powerRow.x + pearlSlot.x
        readonly property real placeY: powerRow.y + pearlSlot.y

        x: root.pearlFrom.x + (placeX - root.pearlFrom.x) * t
        y: root.pearlFrom.y + (placeY - root.pearlFrom.y) * t
        width: root.pearlFrom.w + (Tokens.powerClockSize - root.pearlFrom.w) * t
        height: root.pearlFrom.h + (Tokens.powerClockSize - root.pearlFrom.h) * t
        visible: root.pearlOut && !root.pearlHandedOff

        activity: Config.options.lock.activity
        resting: pearlForm.target !== 1
        spec: pearlForm.spec
        contentOpacity: pearlContent.value
        travel: pearlForm.velocity * (placeY - root.pearlFrom.y)
    }

    mask: Region {
        Region { item: powerInput }
        Region { item: menuCatcher }
        Region { item: appMenu }
        Region { item: dock }
        Region { item: navigator }
        Region { item: workspaces }
        Region { item: spotlight }
        Region { item: status }
    }

    // ── placing the cays ────────────────────────────────────────
    // Config bar.cays orders them: those before "|" pack from the start (left, or top on
    // the left), the rest from the far end. Positions come from each cay's target size and
    // spring there (spatial-default), so a cay that grows pushes its neighbours with the
    // same motion and a reorder slides into place. Along the bottom cays are bottom-aligned
    // (the Navigator grows up into search); on the left they're left-aligned (it grows
    // out to the right). For the power actions everything but the Navigator and Status
    // steps aside and the Navigator slides to the start.
    readonly property var order: BarCays.order
    readonly property var cays: ({ dock: dock, navigator: navigator, workspaces: workspaces, spotlight: spotlight, status: status })

    function sizeOf(id) {
        const c = cays[id];
        if (!c || !inLayout(id))
            return 0;
        return barLeft ? c.targetHeight : c.targetWidth;
    }
    function inLayout(id) {
        if (power && id !== "navigator" && id !== "status")
            return false;
        if (id === "dock")
            return dock.visible;
        if (id === "workspaces")
            return Config.options.bar.workspacesCay;
        return true;
    }
    // Offset of a cay from its group's edge.
    function offsetOf(id) {
        const split = order.indexOf("|");
        const start = order.slice(0, split), end = order.slice(split + 1).reverse();
        const group = start.includes(id) ? start : end;
        let off = 0;
        for (const other of group) {
            if (other === id)
                break;
            const size = sizeOf(other);
            if (size > 0.5)
                off += size + Tokens.space2;
        }
        return off;
    }
    function fromEnd(id) {
        return order.indexOf(id) > order.indexOf("|");
    }
    // Along the bar: x along the bottom, y on the left.
    function alongTarget(id) {
        const c = cays[id];
        const startInset = barLeft ? 0 : leftInset.value;
        const endInset = barLeft ? 0 : rightInset.value;
        const length = barLeft ? height : width;
        return fromEnd(id) ? length - Tokens.space2 - endInset - offsetOf(id) - sizeOf(id)
            : Tokens.space2 + startInset + offsetOf(id);
    }

    Spring {
        id: asideFade
        spec: Motion.effectsFast
        target: root.power ? 0 : 1
    }

    // Where a cay goes, given its spring along the bar: the end group keeps its far edge
    // fixed while the cay grows or shrinks; across the bar cays sit on the screen edge.
    function xFor(id, along) {
        const c = cays[id];
        if (barLeft)
            return Tokens.space2 + leftInset.value;
        return fromEnd(id) ? alongTarget(id) + (c.targetWidth - c.width) : along;
    }
    function yFor(id, along) {
        const c = cays[id];
        if (!barLeft)
            return height - Tokens.space2 - c.height;
        return fromEnd(id) ? alongTarget(id) + (c.targetHeight - c.height) : along;
    }
    Spring { id: dockAlong; spec: Motion.spatialDefault; target: root.alongTarget("dock") }
    Spring { id: navigatorAlong; spec: Motion.spatialDefault; target: root.alongTarget("navigator") }
    Spring { id: workspacesAlong; spec: Motion.spatialDefault; target: root.alongTarget("workspaces") }
    Spring { id: spotlightAlong; spec: Motion.spatialDefault; target: root.alongTarget("spotlight") }
    Spring { id: statusAlong; spec: Motion.spatialDefault; target: root.alongTarget("status") }

    Dock {
        id: dock
        x: root.xFor("dock", dockAlong.value)
        y: root.yFor("dock", dockAlong.value)
        vertical: root.barLeft
        opacity: asideFade.value
        enabled: !root.power
    }
    Navigator {
        id: navigator
        x: root.xFor("navigator", navigatorAlong.value)
        y: root.yFor("navigator", navigatorAlong.value)
        vertical: root.barLeft
        screenName: root.modelData.name
    }
    WorkspacesCay {
        id: workspaces
        x: root.xFor("workspaces", workspacesAlong.value)
        y: root.yFor("workspaces", workspacesAlong.value)
        vertical: root.barLeft
        screenName: root.modelData.name
        visible: Config.options.bar.workspacesCay && opacity > 0.01
        opacity: asideFade.value
        enabled: !root.power
    }
    Spotlight {
        id: spotlight
        x: root.xFor("spotlight", spotlightAlong.value)
        y: root.yFor("spotlight", spotlightAlong.value)
        vertical: root.barLeft
        opacity: asideFade.value
        enabled: !root.power
    }
    // ── the app menu ────────────────────────────────────────────
    // While it's open a click anywhere else on this screen closes it (and goes no further).
    MouseArea {
        id: menuCatcher
        width: appMenu.open ? root.width : 0
        height: appMenu.open ? root.height : 0
        z: 1
        acceptedButtons: Qt.AllButtons
        onPressed: appMenu.hide()
    }
    AppMenu {
        id: appMenu
        z: 2
        barLeft: root.barLeft
        // The keyboard goes back where it was.
        property Item returnTo: null
        onDismissed: {
            if (root.searching)
                navigator.refocusSearch();
            else if (returnTo && root.keyboardActive)
                returnTo.forceActiveFocus();
            returnTo = null;
        }
    }
    Connections {
        target: dock
        function onMenuRequested(app, tile) {
            appMenu.returnTo = tile;
            appMenu.show(app, "dock", tile, null);
        }
    }
    Connections {
        target: navigator
        function onAppMenuRequested(app, row, at) {
            appMenu.show(app, "search", row, at);
        }
    }
    // A menu never outlives its surface's other states.
    Connections {
        target: PanelState
        function onPanelChanged() { if (PanelState.panel !== "search") appMenu.hide(); }
    }

    Status {
        id: status
        x: root.xFor("status", statusAlong.value)
        y: root.yFor("status", statusAlong.value)
        vertical: root.barLeft
        screenName: root.modelData.name
        keyboardActive: root.keyboardActive
    }
}
