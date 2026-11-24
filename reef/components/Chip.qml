import QtQuick
import qs.theme

// A small pill button with a label (Clear all, notification actions, Reply).
// tone: "accent" (primary) or "neutral" (surface-container-high / -highest).
Item {
    id: root

    property string text: ""
    property string tone: "neutral"
    property color neutralColor: Colors.surfaceContainerHigh
    signal clicked

    implicitWidth: label.implicitWidth + Tokens.space3_5 * 2
    implicitHeight: Tokens.chipHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    readonly property color fg: tone === "accent" ? Colors.on.primary : Colors.on.surface

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Tokens.radiusSm : root.height / 2
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: root.tone === "accent" ? Colors.primary : root.neutralColor
        border.width: root.activeFocus ? 2 : 0
        border.color: root.tone === "accent" ? Colors.on.surface : Colors.primary

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.fg
            opacity: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse ? Tokens.stateHoverOpacity : 0
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        style: "chipLabel"
        color: root.fg
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
