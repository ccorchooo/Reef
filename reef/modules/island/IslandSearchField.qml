import QtQuick
import qs.theme
import qs.components

// A search field inside the Island (Clipboard, emoji): an island-container pill with a
// search glyph. Up/Down/Enter are passed on through the signals, so the list below can
// move its selection while typing stays here.
//
//   IslandSearchField { placeholder: "Search clipboard"; onTextChanged: Clipboard.query = text }
FocusScope {
    id: root

    property string placeholder: ""
    property alias text: input.text
    signal accepted
    signal moved(int by)

    implicitHeight: Tokens.islandFieldHeight

    function clear() {
        input.text = "";
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.islandContainer
        border.width: input.activeFocus ? 2 : 0
        border.color: Colors.islandAccent
    }

    Icon {
        id: glyph
        x: Tokens.space4
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        size: Tokens.iconMd
        color: Colors.on.islandVariant
    }

    TextInput {
        id: input
        anchors.left: glyph.right
        anchors.right: parent.right
        anchors.leftMargin: Tokens.space2_5
        anchors.rightMargin: Tokens.space4
        anchors.verticalCenter: parent.verticalCenter
        focus: true
        clip: true
        color: Colors.on.island
        selectionColor: Colors.islandAccent
        selectedTextColor: Colors.on.islandAccent
        font: Type.font("bodyMd")
        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onDownPressed: root.moved(1)
        Keys.onUpPressed: root.moved(-1)

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            style: "bodyMd"
            color: Colors.on.islandVariant
            text: root.placeholder
        }
    }
}
