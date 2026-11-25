import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// Dock cay: pinned and running apps (SURFACES.md → Bar).
// Click launches or focuses (and cycles windows); middle-click opens a new window;
// right-click (or the Menu key, Shift+F10) asks the bar for the app menu (AppMenu).
// On the left (`vertical`) the tiles stack and the running dot sits on the edge side.
Cay {
    id: root

    leftPadding: vertical ? Tokens.cayPaddingTight : Tokens.space2
    rightPadding: vertical ? Tokens.cayPaddingTight : Tokens.space2
    visible: Apps.dock.length > 0

    // Right-click or the Menu key on a tile: { id, entry } and the tile.
    signal menuRequested(var app, Item tile)

    Accessible.role: Accessible.ToolBar
    Accessible.name: "Dock"

    Grid {
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 99   // one row, or one column on the left
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
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                        root.menuRequested(tile.modelData, tile);
                        event.accepted = true;
                    }
                }

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

                // Running indicator, centered in the cay padding on the screen-edge side
                // (under the tile; left of it with the bar on the left).
                Rectangle {
                    readonly property real offset: (Tokens.cayHeight - Tokens.dockTile) / 4 - width / 2
                    x: root.vertical ? -offset - width : (parent.width - width) / 2
                    y: root.vertical ? (parent.height - height) / 2 : parent.height + offset
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
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton)
                            root.menuRequested(tile.modelData, tile);
                        else if (event.button === Qt.MiddleButton) {
                            if (tile.modelData.entry)
                                Apps.launch(tile.modelData.entry);
                        }
                        else
                            Apps.activate(tile.modelData);
                    }
                }
            }
        }
    }
}
