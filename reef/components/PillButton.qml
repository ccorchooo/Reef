import QtQuick
import qs.theme

// A full-width text button (dialogs: Cancel, Authenticate). radius-full; pressing
// squashes the corners toward radius-md (DESIGN.md §4).
//
//   PillButton { text: "Authenticate"; accent: true; onClicked: … }
Item {
    id: root

    property string text: ""
    // Primary fill for the confirming button; surface-container-high otherwise.
    property bool accent: false
    property bool enabledState: true
    signal clicked

    implicitHeight: Tokens.dialogButtonHeight
    implicitWidth: label.implicitWidth + Tokens.space6 * 2
    opacity: enabledState ? 1 : Tokens.disabledOpacity

    activeFocusOnTab: enabledState
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: if (enabledState) clicked()
    Keys.onSpacePressed: if (enabledState) clicked()

    readonly property color fill: accent ? Colors.primary : Colors.surfaceContainerHigh
    readonly property color content: accent ? Colors.on.primary : Colors.on.surface

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Tokens.radiusMd : root.height / 2
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: root.fill
        border.width: root.activeFocus ? 2 : 0
        border.color: root.accent ? Colors.on.primary : Colors.primary

        // State layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.content
            opacity: hover.value
            Spring {
                id: hover
                spec: Motion.effectsFast
                target: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse && root.enabledState ? Tokens.stateHoverOpacity : 0
            }
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        style: root.accent ? "buttonLabelEmphasized" : "buttonLabel"
        text: root.text
        color: root.content
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
