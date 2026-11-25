import QtQuick
import qs.theme
import qs.components

// A text (and optional icon) button on the Island's black: the Shelf's Clear, calculator
// keys, the Tools tab's actions. radius-full; pressing squashes the corners toward
// `pressedRadius` (DESIGN.md §4). Set `radius` lower to hold it squashed (a pending
// calculator operator).
//
//   IslandTextButton { text: "Clear"; onClicked: Shelf.clear() }
Item {
    id: root

    property string text: ""
    property string icon: ""
    property string label: text
    property string textStyle: "toastLabel"
    property real iconSize: Tokens.iconSm
    property color color: Colors.islandContainerHigh
    property color contentColor: Colors.on.island
    property real radius: height / 2
    property real pressedRadius: Tokens.radiusMd
    property real padding: Tokens.cayPadding
    property bool enabledState: true
    signal clicked

    implicitHeight: Tokens.chipHeight
    implicitWidth: row.implicitWidth + padding * 2
    opacity: enabledState ? 1 : Tokens.disabledOpacity

    activeFocusOnTab: enabledState
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: if (enabledState) clicked()
    Keys.onSpacePressed: if (enabledState) clicked()

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Math.min(root.pressedRadius, root.radius) : root.radius
    }
    ColorSpring {
        id: fill
        spec: Motion.effectsDefault
        target: root.color
    }
    ColorSpring {
        id: ink
        spec: Motion.effectsDefault
        target: root.contentColor
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: fill.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.islandAccent

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: ink.value
            opacity: hover.value
            Spring {
                id: hover
                spec: Motion.effectsFast
                target: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse && root.enabledState ? Tokens.stateHoverOpacity : 0
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.space1 + Tokens.spaceHalf
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            size: root.iconSize
            filled: true
            color: ink.value
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            style: root.textStyle
            text: root.text
            color: ink.value
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabledState
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
