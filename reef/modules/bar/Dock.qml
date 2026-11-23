import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// Dock cay: pinned and running apps (SURFACES.md → Bar).
// Click launches or focuses (and cycles windows); middle-click opens a new window.
Cay {
    id: root

    leftPadding: Tokens.space2
    rightPadding: Tokens.space2
    visible: Apps.dock.length > 0

    Accessible.role: Accessible.ToolBar
    Accessible.name: "Dock"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space1

        Repeater {
            model: ScriptModel {
                values: Apps.dock
                objectProp: "id"
            }

            Item {
                id: tile
                required property var modelData
                readonly property bool hovered: mouse.containsMouse

                width: Tokens.dockTile
                height: Tokens.dockTile

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: Apps.nameFor(modelData) + (modelData.focused ? ", focused" : modelData.running ? ", running" : "")
                Keys.onReturnPressed: Apps.activate(modelData)
                Keys.onSpacePressed: Apps.activate(modelData)

                ColorSpring {
                    id: tileBg
                    spec: Motion.effectsFast
                    target: tile.modelData.focused ? Colors.secondaryContainer : tile.hovered ? Colors.surfaceContainerHighest : Qt.alpha(Colors.surfaceContainerHighest, 0)
                }

                Spring {
                    id: corner
                    spec: Motion.spatialFast
                    target: mouse.pressed ? Tokens.radiusSm : Tokens.radiusTileSm
                }

                Rectangle {
                    anchors.fill: parent
                    radius: corner.value
                    color: tileBg.value
                    border.width: tile.activeFocus ? 2 : 0
                    border.color: Colors.primary
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Tokens.dockAppIcon
                    source: Apps.iconFor(tile.modelData)
                    scale: mouse.pressed ? 0.92 : 1
                    Behavior on scale { MotionAnimation { spec: Motion.spatialFast } }
                }

                // Running indicator, centered in the cay padding under the tile.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: (Tokens.cayHeight - Tokens.dockTile) / 4 - height / 2
                    width: Tokens.runningDot
                    height: Tokens.runningDot
                    radius: width / 2
                    color: tile.modelData.focused ? Colors.on.surface : Colors.on.surfaceVariant
                    opacity: dotOpacity.value
                    Spring {
                        id: dotOpacity
                        spec: Motion.effectsDefault
                        target: tile.modelData.running ? 1 : 0
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            tile.modelData.entry?.execute();
                        else
                            Apps.activate(tile.modelData);
                    }
                }
            }
        }
    }
}
