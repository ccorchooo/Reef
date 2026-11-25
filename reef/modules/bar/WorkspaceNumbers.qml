import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules

// Workspace numerals with the active one in a primary pill that slides between them
// (SURFACES.md → Bar, screens/Workspaces). Workspaces with windows sit on a subtle
// surface-container-high circle; empty ones are on-surface-variant. With the overview open
// the pill shows (and clicks move) the overview's selection. Shared by the Navigator's
// workspaces form and the separate Workspaces cay.
Item {
    id: root

    required property string screenName
    property bool vertical: false

    readonly property bool overview: PanelState.panel === "overview" && PanelState.screenName === screenName
    readonly property var ids: Workspaces.ids(Config.options.bar.workspaceCount)
    readonly property int activeId: overview ? PanelState.overviewWorkspace : Workspaces.activeOn(screenName)
    readonly property int activeIndex: ids.indexOf(activeId)

    implicitWidth: items.implicitWidth
    implicitHeight: items.implicitHeight

    function step(by) {
        if (overview) {
            const i = Math.max(0, Math.min(ids.length - 1, ids.indexOf(PanelState.overviewWorkspace) + by));
            PanelState.overviewWorkspace = ids[i];
        } else {
            Workspaces.step(by);
        }
    }

    // The active pill slides along the bar.
    Rectangle {
        visible: root.activeIndex >= 0
        width: Tokens.cayItemSm
        height: Tokens.cayItemSm
        radius: height / 2
        x: root.vertical ? 0 : along.value
        y: root.vertical ? along.value : 0
        color: Colors.primary

        Spring {
            id: along
            spec: Motion.spatialDefault
            target: Math.max(0, root.activeIndex) * (Tokens.cayItemSm + items.spacing)
        }
    }

    Grid {
        id: items
        columns: root.vertical ? 1 : 99   // one row, or one column on the left
        spacing: Tokens.spaceHalf

        Repeater {
            model: root.ids

            Item {
                id: ws
                required property int modelData
                readonly property bool active: modelData === root.activeId
                readonly property bool occupied: Workspaces.occupied(modelData)

                width: Tokens.cayItemSm
                height: Tokens.cayItemSm

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: `Workspace ${modelData}` + (active ? ", current" : occupied ? `, ${Workspaces.windowCount(modelData)} windows` : ", empty")
                Keys.onReturnPressed: ws.choose()
                Keys.onSpacePressed: ws.choose()

                // With the overview open this selects the workspace there; otherwise it
                // goes to it.
                function choose() {
                    if (root.overview)
                        PanelState.overviewWorkspace = modelData;
                    else
                        Workspaces.goTo(modelData);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
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
