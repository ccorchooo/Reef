import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules
import qs.modules.search

// Navigator cay (SURFACES.md → Bar): home, search, workspaces. It re-forms in place for
// each form with spatial-default; the old content fades out (effects-fast) and the new one
// fades in after content-fade-delay (MOTION.md → Shape follows content).
// Forms: home, workspaces (its own mode), and search: the cay grows up into the search
// panel (screens/Search) with the field where the cay was. Power (Ctrl+Alt+Delete,
// screens/PowerActions): the icons scale away, the cay re-forms to the power actions
// (power-cay-height) and they pop in staggered; hovering Power off turns it
// error-container with a tooltip.
Cay {
    id: root

    required property string screenName
    property string mode: "home"             // home | workspaces
    readonly property bool searching: PanelState.panel === "search" && PanelState.screenName === screenName
    // The workspace overview shows the workspaces here too (screens/Workspaces).
    readonly property bool overview: PanelState.panel === "overview" && PanelState.screenName === screenName
    // Holding Super shows the workspaces here (not the overview).
    readonly property bool superHeld: PanelState.superHeld && PanelState.superScreen === screenName
    readonly property bool power: PanelState.panel === "power" && PanelState.screenName === screenName
    readonly property string form: power ? "power" : searching ? "search" : overview || superHeld ? "workspaces" : mode
    property string shownForm: form

    leftPadding: form === "search" ? Tokens.space2 : form === "power" ? Tokens.cayPaddingTight : Tokens.space1
    rightPadding: form === "search" ? Tokens.space2 : form === "workspaces" || form === "power" ? Tokens.cayPaddingTight : Tokens.space1
    contentWidth: form === "search" ? Tokens.searchWidth - Tokens.space2 * 2
        : form === "workspaces" ? wsRow.implicitWidth : form === "power" ? powerRow.implicitWidth : homeRow.implicitWidth
    targetHeight: form === "search" ? searchView.implicitHeight + Tokens.space2 * 2 : form === "power" ? Tokens.powerCayHeight : Tokens.cayHeight
    targetRadius: form === "search" ? Tokens.radiusXl : form === "power" ? Tokens.powerCayHeight / 2 : Tokens.cayHeight / 2
    // The Power off tooltip sits above the cay.
    clipContent: form !== "power"

    Accessible.role: Accessible.ToolBar
    Accessible.name: form === "power" ? "Power actions" : form === "search" ? "Search" : form === "workspaces" ? "Navigator, workspaces" : "Navigator"

    onFormChanged: {
        if (Motion.reduceMotion) {
            shownForm = form;
            return;
        }
        shownForm = "";
        fadeIn.restart();
    }

    Timer {
        id: fadeIn
        interval: Motion.contentFadeDelay
        onTriggered: root.shownForm = root.form
    }

    // The bar calls this once the surface has the keyboard.
    function focusSearch() {
        searchView.open();
    }
    // The bar calls this once the surface has the keyboard for the power actions.
    function focusPower() {
        powerButtons.itemAt(0)?.forceActiveFocus();
    }

    Binding {
        target: Search
        property: "active"
        value: true
        when: root.searching
    }

    // Scrolling anywhere on the Navigator moves between workspaces.
    WheelHandler {
        enabled: !root.searching
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) < 1)
                return;
            if (root.overview) {
                // Moves the overview's selection; the overview follows.
                const ids = wsRow.ids;
                const i = Math.max(0, Math.min(ids.length - 1, ids.indexOf(PanelState.overviewWorkspace) + (d < 0 ? 1 : -1)));
                PanelState.overviewWorkspace = ids[i];
                return;
            }
            root.mode = "workspaces";
            Workspaces.step(d < 0 ? 1 : -1);
        }
    }

    // ── home ────────────────────────────────────────────────────
    Row {
        id: homeRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space1
        opacity: homeOpacity.value
        // Into the power actions the icons scale away (MOTION.md → Power menu).
        scale: root.form === "power" ? homeOpacity.value : 1
        visible: opacity > 0.01
        enabled: root.form === "home"

        Spring {
            id: homeOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownForm === "home" ? 1 : 0
        }

        CayButton {
            label: "Home"
            selected: true
            onClicked: Actions.run("home")
            Logo {
                anchors.centerIn: parent
                size: Tokens.iconSm
                color: Colors.on.primaryContainer
            }
        }
        CayButton {
            icon: "search"
            label: "Search"
            onClicked: PanelState.toggle("search", root.screenName)
        }
        CayButton {
            icon: "grid_view"
            label: "Workspace overview"
            onClicked: PanelState.toggle("overview", root.screenName)
        }
    }

    // ── workspaces ──────────────────────────────────────────────
    Item {
        id: wsRow
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: wsItems.implicitWidth
        height: Tokens.cayButton
        opacity: wsOpacity.value
        visible: opacity > 0.01
        enabled: root.form === "workspaces"

        readonly property var ids: Workspaces.ids(Config.options.bar.workspaceCount)
        // With the overview open, the pill shows (and moves) its selection instead.
        readonly property int activeId: root.overview ? PanelState.overviewWorkspace : Workspaces.activeOn(root.screenName)
        readonly property int activeIndex: ids.indexOf(activeId)

        Spring {
            id: wsOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownForm === "workspaces" ? 1 : 0
        }

        // The active pill slides between numerals.
        Rectangle {
            id: pill
            visible: wsRow.activeIndex >= 0
            width: Tokens.cayItemSm
            height: Tokens.cayItemSm
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: pillX.value
            color: Colors.primary

            Spring {
                id: pillX
                spec: Motion.spatialDefault
                target: closeBtn.width + wsItems.spacing + Math.max(0, wsRow.activeIndex) * (Tokens.cayItemSm + wsItems.spacing)
            }
        }

        Row {
            id: wsItems
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spaceHalf

            CayButton {
                id: closeBtn
                icon: "grid_view"
                label: root.overview ? "Close the overview" : "Close workspaces"
                selected: true
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.overview ? PanelState.closeAll() : (root.mode = "home")
            }

            Repeater {
                model: wsRow.ids

                Item {
                    id: ws
                    required property int modelData
                    readonly property bool active: modelData === wsRow.activeId
                    readonly property bool occupied: Workspaces.occupied(modelData)

                    width: Tokens.cayItemSm
                    height: Tokens.cayItemSm
                    anchors.verticalCenter: parent.verticalCenter

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: `Workspace ${modelData}` + (active ? ", current" : occupied ? `, ${Workspaces.windowCount(modelData)} windows` : ", empty")
                    Keys.onReturnPressed: ws.choose()
                    Keys.onSpacePressed: ws.choose()

                    // With the overview open this selects the workspace there; otherwise
                    // it goes to it.
                    function choose() {
                        if (root.overview)
                            PanelState.overviewWorkspace = modelData;
                        else
                            Workspaces.goTo(modelData);
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        // Hover, or a subtle tint on a workspace that has windows.
                        color: ws.active ? "transparent"
                            : wsMouse.containsMouse ? Colors.surfaceContainerHighest
                            : ws.occupied ? Colors.surfaceContainerHigh : "transparent"
                        border.width: ws.activeFocus ? 2 : 0
                        border.color: Colors.primary
                    }

                    // The active numeral is 700: a crossfade between two fixed weights, since
                    // animating the wght axis builds a new font instance every frame.
                    Spring {
                        id: boldness
                        spec: Motion.effectsFast
                        target: ws.active ? 1 : 0
                    }
                    ColorSpring {
                        id: numColor
                        spec: Motion.effectsDefault
                        target: ws.active ? Colors.on.primary : ws.occupied ? Colors.on.surface : Colors.on.surfaceVariant
                    }
                    StyledText {
                        anchors.centerIn: parent
                        style: "barNumeral"
                        text: ws.modelData
                        color: numColor.value
                        opacity: 1 - Math.max(0, Math.min(1, boldness.value))
                    }
                    StyledText {
                        anchors.centerIn: parent
                        style: "barNumeral"
                        text: ws.modelData
                        weight: 700
                        color: numColor.value
                        opacity: Math.max(0, Math.min(1, boldness.value))
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ws.choose()
                    }
                }
            }
        }
    }

    // ── power ───────────────────────────────────────────────────
    Row {
        id: powerRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space1
        opacity: powerOpacity.value
        visible: opacity > 0.01
        enabled: root.form === "power"

        Spring {
            id: powerOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownForm === "power" ? 1 : 0
        }

        Repeater {
            id: powerButtons
            model: [
                { icon: "lock", label: "Lock", run: () => { PanelState.closeAll(); Session.lock(); } },
                { icon: "logout", label: "Log out", run: () => Session.logout() },
                { icon: "bedtime", label: "Sleep", run: () => { PanelState.closeAll(); Session.suspend(); } },
                { icon: "restart_alt", label: "Restart", run: () => Session.reboot() },
                { icon: "power_settings_new", label: "Power off", danger: true, run: () => Session.poweroff() },
                { icon: "close", label: "Cancel", run: () => PanelState.closeAll() }
            ]

            CayButton {
                id: powerButton
                required property var modelData
                required property int index
                readonly property bool danger: modelData.danger ?? false
                anchors.verticalCenter: parent.verticalCenter
                size: Tokens.powerButton
                icon: modelData.icon
                label: modelData.label
                filled: false
                contentColor: Colors.on.surface
                // Power off warns on hover or focus.
                selected: danger && (hovered || activeFocus)
                selectedColor: Colors.errorContainer
                selectedContentColor: Colors.on.errorContainer
                scale: Math.max(0, pop.value)
                onClicked: modelData.run()
                Keys.onLeftPressed: powerButtons.itemAt(Math.max(0, index - 1))?.forceActiveFocus()
                Keys.onRightPressed: powerButtons.itemAt(Math.min(powerButtons.count - 1, index + 1))?.forceActiveFocus()

                // Pops in staggered once the cay has re-formed (Motion.stagger).
                Spring {
                    id: pop
                    spec: Motion.spatialFast
                    target: 0
                }
                Timer {
                    interval: Math.max(1, Motion.stagger(powerButton.index))
                    running: root.shownForm === "power"
                    onTriggered: pop.target = 1
                }
                Connections {
                    target: root
                    function onFormChanged() {
                        if (root.form !== "power")
                            pop.target = 0;
                    }
                }

                Rectangle {
                    visible: powerButton.danger
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: (Tokens.powerCayHeight - Tokens.powerButton) / 2 + Tokens.space2
                    width: tip.implicitWidth + Tokens.cayPadding * 2
                    height: Tokens.chipHeight
                    radius: height / 2
                    color: Colors.errorContainer
                    opacity: tipFade.value
                    Spring {
                        id: tipFade
                        spec: Motion.effectsFast
                        target: powerButton.selected ? 1 : 0
                    }
                    StyledText {
                        id: tip
                        anchors.centerIn: parent
                        style: "tooltip"
                        color: Colors.on.errorContainer
                        text: powerButton.label
                    }
                }
            }
        }
    }

    // ── search ──────────────────────────────────────────────────
    SearchView {
        id: searchView
        width: Tokens.searchWidth - Tokens.space2 * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space2
        opacity: searchOpacity.value
        visible: opacity > 0.01
        enabled: root.searching

        Spring {
            id: searchOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownForm === "search" ? 1 : 0
        }
    }
}
