import QtQuick
import qs.theme
import qs.components

// A large choice (screens/Settings → Home logo): a glyph over a caption on a
// surface-container-highest radius-option card; the chosen one gets a primary ring.
//
//   OptionCard { text: "Reef"; selected: …; onClicked: …; Logo { … } }
Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool selected: false
    default property alias glyph: glyphHolder.data
    signal clicked

    implicitHeight: Tokens.settingsOptionHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.checked: selected
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Tokens.radiusMd : Tokens.radiusOption
    }
    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: Colors.surfaceContainerHighest
        border.width: root.selected || root.activeFocus ? 2 : 0
        border.color: Colors.primary

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.surface
            opacity: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse ? Tokens.stateHoverOpacity : 0
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: Tokens.space2
        Item {
            id: glyphHolder
            anchors.horizontalCenter: parent.horizontalCenter
            width: Tokens.settingsOptionGlyph
            height: Tokens.settingsOptionGlyph
            Icon {
                anchors.centerIn: parent
                visible: root.icon !== ""
                name: root.icon
                size: Tokens.settingsOptionGlyph
                color: Colors.on.surfaceVariant
            }
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            style: "optionLabel"
            text: root.text
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
