import QtQuick
import QtQuick.Effects
import qs.theme
import qs.components

// The expanded Island's tabs (parts/Island-Now): a column of small black circles to
// the left of the Island, so the Island itself keeps all its room for the tab.
// The current tab sits on island-container-high with its icon filled in the accent.
Column {
    id: root

    // Shadow strength, shared with the Island (only shown over apps).
    property real shadowOpacity: 0

    spacing: Tokens.space2

    Repeater {
        model: IslandState.tabs

        Item {
            id: tab
            required property var modelData
            readonly property bool current: IslandState.tab === modelData.id

            width: Tokens.islandTab
            height: Tokens.islandTab

            activeFocusOnTab: true
            Accessible.role: Accessible.PageTab
            Accessible.name: modelData.label
            Accessible.selected: current
            Keys.onReturnPressed: IslandState.open(modelData.id)
            Keys.onSpacePressed: IslandState.open(modelData.id)

            RectangularShadow {
                anchors.fill: circle
                radius: circle.radius
                offset.x: Colors.shadowIsland.x
                offset.y: Colors.shadowIsland.y
                blur: Colors.shadowIsland.blur
                color: Colors.shadowIsland.color
                opacity: root.shadowOpacity
                visible: opacity > 0.01
            }

            Rectangle {
                id: circle
                anchors.fill: parent
                radius: width / 2
                color: bg.value
                border.width: tab.activeFocus ? 2 : 0
                border.color: Colors.islandAccent
                ColorSpring {
                    id: bg
                    spec: Motion.effectsFast
                    target: tab.current ? Colors.islandContainerHigh : mouse.containsMouse ? Colors.islandContainer : Colors.island
                }
            }

            Icon {
                anchors.centerIn: parent
                visible: tab.modelData.icon !== ""
                name: tab.modelData.icon
                size: Tokens.iconSm
                filled: tab.current
                color: tab.current ? Colors.islandAccent : Colors.on.islandVariant
            }

            // Coral's glyph is a ring.
            Rectangle {
                anchors.centerIn: parent
                visible: tab.modelData.icon === ""
                width: Tokens.coralRing
                height: Tokens.coralRing
                radius: width / 2
                color: "transparent"
                border.width: Tokens.spaceHalf
                border.color: tab.current ? Colors.islandAccent : Colors.on.islandVariant
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.open(tab.modelData.id)
            }
        }
    }
}
