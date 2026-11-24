import QtQuick
import qs.theme

// M3 switch (screens/QuickMenus): primary track with a check in the thumb when on;
// outlined track with a small thumb when off. The thumb grows and slides with spatial-fast.
Item {
    id: root

    property bool checked: false
    property string label: ""
    signal toggled

    implicitWidth: Tokens.switchWidth
    implicitHeight: Tokens.switchHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Keys.onReturnPressed: toggled()
    Keys.onSpacePressed: toggled()

    readonly property real _inset: (height - Tokens.switchThumb) / 2

    ColorSpring { id: track; target: root.checked ? Colors.primary : Colors.surfaceContainerHighest }
    ColorSpring { id: thumbColor; target: root.checked ? Colors.on.primary : Colors.outline }
    Spring { id: thumbSize; spec: Motion.spatialFast; target: mouse.pressed ? Tokens.switchThumb + Tokens.space1 : root.checked ? Tokens.switchThumb : Tokens.switchThumbOff }
    Spring { id: thumbX; spec: Motion.spatialFast; target: root.checked ? root.width - root._inset - Tokens.switchThumb / 2 : root._inset + Tokens.switchThumb / 2 }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: track.value
        border.width: root.checked ? 0 : 2
        border.color: Colors.outline
    }

    Rectangle {
        width: thumbSize.value
        height: width
        radius: width / 2
        x: thumbX.value - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: thumbColor.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary

        Icon {
            anchors.centerIn: parent
            visible: root.checked
            name: "check"
            size: Tokens.iconXs
            color: Colors.primary
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
