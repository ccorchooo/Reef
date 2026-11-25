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
// On the left (`vertical`) every form stacks; search grows out to the right.
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
    // With the separate Workspaces cay the Navigator stays in its home form.
    readonly property bool ownCay: Config.options.bar.workspacesCay
    readonly property string form: power ? "power" : searching ? "search" : ownCay ? "home" : overview || superHeld ? "workspaces" : mode
    property string shownForm: form

    leftPadding: form === "search" ? Tokens.space2 : form === "power" ? Tokens.cayPaddingTight : Tokens.space1
    rightPadding: form === "search" ? Tokens.space2 : form === "workspaces" || form === "power" ? Tokens.cayPaddingTight : Tokens.space1
    contentWidth: form === "search" ? Tokens.searchWidth - Tokens.space2 * 2
        : form === "workspaces" ? wsRow.implicitWidth : form === "power" ? powerRow.implicitWidth : homeRow.implicitWidth
    contentHeight: form === "workspaces" ? wsRow.implicitHeight : form === "power" ? powerRow.implicitHeight : homeRow.implicitHeight
    targetWidth: !vertical ? contentWidth + leftPadding + rightPadding
        : form === "search" ? Tokens.searchWidth : form === "power" ? Tokens.powerCayHeight : Tokens.cayHeight
    targetHeight: form === "search" ? searchView.implicitHeight + Tokens.space2 * 2
        : vertical ? contentHeight + leftPadding + rightPadding
        : form === "power" ? Tokens.powerCayHeight : Tokens.cayHeight
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
            // Moves the overview's selection while it's open, otherwise the workspace.
            numbers.step(d < 0 ? 1 : -1);
            if (!root.overview && !root.ownCay)
                root.mode = "workspaces";
        }
    }

    // ── home ────────────────────────────────────────────────────
    Grid {
        id: homeRow
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 99   // one row, or one column on the left
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
            HomeLogo {
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
    Grid {
        id: wsRow
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 99
        spacing: Tokens.spaceHalf
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter
        opacity: wsOpacity.value
        visible: opacity > 0.01
        enabled: root.form === "workspaces"

        readonly property var ids: numbers.ids

        Spring {
            id: wsOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownForm === "workspaces" ? 1 : 0
        }

        CayButton {
            id: closeBtn
            icon: "grid_view"
            label: root.overview ? "Close the overview" : "Close workspaces"
            selected: true
            onClicked: root.overview ? PanelState.closeAll() : (root.mode = "home")
        }
        WorkspaceNumbers {
            id: numbers
            screenName: root.screenName
            vertical: root.vertical
        }
    }

    // ── power ───────────────────────────────────────────────────
    Grid {
        id: powerRow
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 99
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
                Keys.onUpPressed: powerButtons.itemAt(Math.max(0, index - 1))?.forceActiveFocus()
                Keys.onDownPressed: powerButtons.itemAt(Math.min(powerButtons.count - 1, index + 1))?.forceActiveFocus()

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

                // Above the cay; beside it (to the right) with the bar on the left.
                Rectangle {
                    visible: powerButton.danger
                    readonly property real clearance: (Tokens.powerCayHeight - Tokens.powerButton) / 2 + Tokens.space2
                    x: root.vertical ? parent.width + clearance : (parent.width - width) / 2
                    y: root.vertical ? (parent.height - height) / 2 : -clearance - height
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
        x: root.vertical ? Tokens.space2 : 0
        width: Tokens.searchWidth - Tokens.space2 * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.vertical ? 0 : Tokens.space2
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
