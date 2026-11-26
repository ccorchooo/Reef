import QtQuick
import qs.theme
import qs.components

// A round icon button on the Coral app's surfaces (under messages, in the sidebar, the
// composer). Labelled for screen readers; a state layer on hover and press.
//
//   CoralToolButton { icon: "content_copy"; label: "Copy"; onClicked: … }
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool filled: false
    property real size: Tokens.coralAppTool
    property real iconSize: Tokens.iconSm
    property color color: Colors.on.surfaceVariant
    property color fill: Qt.alpha(Colors.surfaceContainerHigh, 0)
    property real radius: width / 2
    property bool enabledState: true
    signal clicked

    implicitWidth: size
    implicitHeight: size
    opacity: enabledState ? 1 : Tokens.disabledOpacity

    activeFocusOnTab: enabledState
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: if (enabledState) clicked()
    Keys.onSpacePressed: if (enabledState) clicked()

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fill
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.color
            opacity: !root.enabledState ? 0 : mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse ? Tokens.stateHoverOpacity : 0
        }
    }
    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        filled: root.filled
        color: root.color
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabledState ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabledState) root.clicked()
    }
}
