import QtQuick
import qs.theme

// A label with a switch at the end (edit mode's Bar card, Settings). Clicking the label
// toggles it too. An optional second line describes the setting.
//
//   SwitchRow { text: "Show Spotlight cay"; checked: …; onToggled: … }
Item {
    id: root

    property string text: ""
    property string description: ""
    property bool checked: false
    signal toggled

    implicitHeight: Math.max(Tokens.switchHeight, labels.implicitHeight)
    opacity: enabled ? 1 : Tokens.disabledOpacity

    Column {
        id: labels
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - toggle.width - Tokens.space3

        StyledText {
            width: parent.width
            style: "rowLabel"
            wrapMode: Text.Wrap
            text: root.text
        }
        StyledText {
            width: parent.width
            visible: text !== ""
            style: "bodySm"
            color: Colors.on.surfaceVariant
            wrapMode: Text.Wrap
            text: root.description
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
    Switch {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        label: root.text
        checked: root.checked
        onToggled: root.toggled()
    }
}
