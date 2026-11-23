import QtQuick
import qs.theme
import qs.components

// A pill button for the dev window. Selected = filled primary (one accent per group).
Rectangle {
    id: root

    property string text: ""
    property bool selected: false
    signal clicked

    implicitWidth: label.implicitWidth + Tokens.space4 * 2
    implicitHeight: Tokens.cayHeight
    radius: height / 2
    color: bg.value
    border.width: activeFocus ? 2 : 0
    border.color: Colors.primary

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: selected
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    ColorSpring {
        id: bg
        target: root.selected ? Colors.primary : mouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        style: "labelLg"
        text: root.text
        color: root.selected ? Colors.on.primary : Colors.on.surface
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
