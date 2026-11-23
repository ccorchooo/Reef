import QtQuick
import qs.theme
import qs.components

// The row of small tab buttons at the bottom of the expanded Island (parts/Island-Now).
Row {
    id: root

    spacing: Tokens.space1

    Repeater {
        model: IslandState.tabs

        Item {
            id: tab
            required property var modelData
            readonly property bool current: IslandState.tab === modelData.id

            width: Tokens.islandTabWidth
            height: Tokens.islandTabHeight

            activeFocusOnTab: true
            Accessible.role: Accessible.PageTab
            Accessible.name: modelData.label
            Accessible.selected: current
            Keys.onReturnPressed: IslandState.open(modelData.id)
            Keys.onSpacePressed: IslandState.open(modelData.id)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: bg.value
                border.width: tab.activeFocus ? 2 : 0
                border.color: Colors.islandAccent
                ColorSpring {
                    id: bg
                    spec: Motion.effectsFast
                    target: tab.current ? Colors.islandContainerHigh : mouse.containsMouse ? Colors.islandContainer : Qt.alpha(Colors.islandContainer, 0)
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
