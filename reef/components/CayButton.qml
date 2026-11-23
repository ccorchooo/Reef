import QtQuick
import qs.theme

// A round button inside a cay (Navigator home/search/workspaces, Spotlight play).
//
//   CayButton { icon: "search"; label: "Search"; onClicked: … }
//
// Hover tints with surface-container-highest; `selected` fills it with primary-container.
// Pressing squashes the corners toward radius-md and springs back (DESIGN.md §4).
// Icon-only, so `label` is required for screen readers.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool filled: selected
    property real size: Tokens.cayButton
    property real iconSize: Tokens.iconMd
    property color selectedColor: Colors.primaryContainer
    property color selectedContentColor: Colors.on.primaryContainer
    property color contentColor: Colors.on.surfaceVariant
    readonly property color currentContentColor: selected ? selectedContentColor : contentColor
    readonly property bool hovered: mouse.containsMouse
    default property alias content: custom.data
    signal clicked
    signal wheel(var event)

    implicitWidth: size
    implicitHeight: size

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: root.selected ? root.selectedColor : root.hovered ? Colors.surfaceContainerHighest : Qt.alpha(Colors.surfaceContainerHighest, 0)
    }

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Math.min(Tokens.radiusMd, root.height / 2) : root.height / 2
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: bg.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary
    }

    Icon {
        anchors.centerIn: parent
        visible: root.icon !== ""
        name: root.icon
        size: root.iconSize
        filled: root.filled
        color: root.currentContentColor
    }

    Item {
        id: custom
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => root.wheel(event)
    }
}
