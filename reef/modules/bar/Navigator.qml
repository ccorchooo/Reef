import QtQuick
import qs.theme
import qs.services
import qs.components

// Navigator cay (SURFACES.md → Bar): home, search, workspaces. It re-forms in place for
// each mode with spatial-default; the old content fades out (effects-fast) and the new one
// fades in after content-fade-delay (MOTION.md → Shape follows content).
// Modes now: home, workspaces. Search and power arrive in M4/M5.
Cay {
    id: root

    required property string screenName
    property string mode: "home"
    property string shownMode: mode

    leftPadding: Tokens.space1
    rightPadding: mode === "workspaces" ? Tokens.cayPaddingTight : Tokens.space1
    contentWidth: mode === "workspaces" ? wsRow.implicitWidth : homeRow.implicitWidth

    Accessible.role: Accessible.ToolBar
    Accessible.name: mode === "workspaces" ? "Navigator, workspaces" : "Navigator"

    onModeChanged: {
        if (Motion.reduceMotion) {
            shownMode = mode;
            return;
        }
        shownMode = "";
        fadeIn.restart();
    }

    Timer {
        id: fadeIn
        interval: Motion.contentFadeDelay
        onTriggered: root.shownMode = root.mode
    }

    // Scrolling anywhere on the Navigator moves between workspaces.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) < 1)
                return;
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
        visible: opacity > 0.01
        enabled: root.mode === "home"

        Spring {
            id: homeOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownMode === "home" ? 1 : 0
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
            onClicked: Actions.run("search")
        }
        CayButton {
            icon: "grid_view"
            label: "Workspaces"
            onClicked: root.mode = "workspaces"
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
        enabled: root.mode === "workspaces"

        readonly property var ids: Workspaces.ids(Config.options.bar.workspaceCount)
        readonly property int activeId: Workspaces.activeOn(root.screenName)
        readonly property int activeIndex: ids.indexOf(activeId)

        Spring {
            id: wsOpacity
            spec: Motion.reduceMotion ? Motion.effectsDefault : Motion.effectsFast
            target: root.shownMode === "workspaces" ? 1 : 0
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
                label: "Close workspaces"
                selected: true
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.mode = "home"
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
                    Keys.onReturnPressed: Workspaces.goTo(modelData)
                    Keys.onSpacePressed: Workspaces.goTo(modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: wsMouse.containsMouse && !ws.active ? Colors.surfaceContainerHighest : "transparent"
                        border.width: ws.activeFocus ? 2 : 0
                        border.color: Colors.primary
                    }

                    StyledText {
                        anchors.centerIn: parent
                        style: "barNumeral"
                        text: ws.modelData
                        weight: weightSpring.value
                        color: numColor.value
                        Spring {
                            id: weightSpring
                            spec: Motion.effectsFast
                            target: ws.active ? 700 : Type.spec("barNumeral").weight
                        }
                        ColorSpring {
                            id: numColor
                            spec: Motion.effectsDefault
                            target: ws.active ? Colors.on.primary : ws.occupied ? Colors.on.surface : Colors.on.surfaceVariant
                        }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Workspaces.goTo(ws.modelData)
                    }
                }
            }
        }
    }
}
