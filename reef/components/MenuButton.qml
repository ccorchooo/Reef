import QtQuick
import qs.theme

// The full-width button at the bottom of a quick menu ("Network settings").
Item {
    id: root

    property string text: ""
    signal clicked

    implicitHeight: Tokens.menuButtonHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.surfaceContainerHigh
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.surface
            opacity: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse ? Tokens.stateHoverOpacity : 0
        }
    }

    StyledText {
        anchors.centerIn: parent
        style: "tileLabel"
        text: root.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
