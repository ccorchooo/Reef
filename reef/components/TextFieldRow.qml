import QtQuick
import qs.theme

// A label over a pill text field (Settings: weather location, Coral's endpoint). The
// value is committed with Enter or when the field loses focus.
//
//   TextFieldRow { text: "Weather location"; value: …; placeholder: "Automatic"; onCommitted: v => … }
Column {
    id: root

    property string text: ""
    property string value: ""
    property string placeholder: ""
    property bool secret: false
    signal committed(string value)

    spacing: Tokens.space2

    StyledText {
        width: parent.width
        style: "rowLabel"
        text: root.text
    }

    Rectangle {
        width: parent.width
        height: Tokens.settingsNavRow
        radius: height / 2
        color: Colors.surfaceContainerHighest
        border.width: input.activeFocus ? 2 : 0
        border.color: Colors.primary

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Tokens.space4
            anchors.rightMargin: Tokens.space4
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Colors.on.surface
            selectionColor: Colors.primaryContainer
            selectedTextColor: Colors.on.primaryContainer
            font: Type.font("bodyMd")
            echoMode: root.secret ? TextInput.Password : TextInput.Normal
            text: root.value
            activeFocusOnTab: true
            Accessible.role: Accessible.EditableText
            Accessible.name: root.text
            onEditingFinished: if (text !== root.value) root.committed(text)

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === "" && !input.activeFocus
                style: "bodyMd"
                color: Colors.on.surfaceVariant
                text: root.placeholder
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.NoButton
        }
    }
}
