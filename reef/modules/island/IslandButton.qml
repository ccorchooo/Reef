import QtQuick
import qs.theme
import qs.components

// A button inside the Island (black surroundings, island colors).
// Round by default; set `radius` for the large play button.
//
//   IslandButton { icon: "skip_next"; label: "Next"; onClicked: Media.next() }
Item {
    id: root

    property string icon: ""
    property string label: ""
    property real iconSize: Tokens.iconLg
    property bool filled: true
    property real radius: Math.min(width, height) / 2
    property color color: Colors.islandContainerHigh
    property color contentColor: Colors.on.island
    property bool enabledState: true
    default property alias content: custom.data
    signal clicked

    implicitWidth: Tokens.islandButton
    implicitHeight: Tokens.islandButton
    opacity: enabledState ? 1 : Tokens.disabledOpacity

    activeFocusOnTab: enabledState
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: if (enabledState) clicked()
    Keys.onSpacePressed: if (enabledState) clicked()

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Math.max(Tokens.radiusSm, root.radius - Tokens.space2) : root.radius
    }

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: root.color
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: bg.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.islandAccent
    }

    // Hover state layer
    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: Colors.on.island
        opacity: hover.value
        Spring {
            id: hover
            spec: Motion.effectsFast
            target: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse && root.enabledState ? Tokens.stateHoverOpacity : 0
        }
    }

    Icon {
        anchors.centerIn: parent
        visible: root.icon !== ""
        name: root.icon
        size: root.iconSize
        filled: root.filled
        color: root.contentColor
    }

    Item {
        id: custom
        anchors.fill: parent
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
