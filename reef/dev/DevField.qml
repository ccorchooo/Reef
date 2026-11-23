import QtQuick
import qs.theme
import qs.components

// A single-line text field (inset well) for the dev window. Commits on Enter.
Rectangle {
    id: root

    property string label: ""
    property string text: ""
    property string placeholder: ""
    signal accepted(string value)

    implicitHeight: Tokens.cayHeight
    radius: height / 2
    color: Colors.surfaceContainerLowest
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Colors.primary : Colors.outlineVariant

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Tokens.space4
        anchors.rightMargin: Tokens.space4
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: root.text
        color: Colors.on.surface
        selectionColor: Colors.secondaryContainer
        selectedTextColor: Colors.on.secondaryContainer
        font: Type.font("monoMd")
        activeFocusOnTab: true
        Accessible.role: Accessible.EditableText
        Accessible.name: root.label
        onAccepted: root.accepted(text)
    }

    StyledText {
        anchors.left: input.left
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0
        style: "monoMd"
        color: Colors.on.surfaceVariant
        text: root.placeholder
    }
}
