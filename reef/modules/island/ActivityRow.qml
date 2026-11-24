import QtQuick
import qs.theme
import qs.components

// A live-activity row on island-container (parts/Island-Now: the timer row): a glyph,
// a label, a readout and trailing buttons. Used by the Now tab and the activities pill.
Rectangle {
    id: row
    property string icon
    property color iconColor: Colors.islandAccent
    property string label
    property color labelColor: Colors.on.island
    property string value
    property color valueColor: Colors.islandAccent
    default property alias trailing: trailingRow.data
    readonly property Item dotSlot: iconSlot

    implicitHeight: Math.max(Tokens.islandButtonSm, labelText.implicitHeight) + Tokens.space2_5 * 2
    radius: Tokens.radiusLg
    color: Colors.islandContainer

    Row {
        anchors.fill: parent
        anchors.leftMargin: Tokens.space3
        anchors.rightMargin: Tokens.space3
        spacing: Tokens.space3

        Item {
            id: iconSlot
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.iconLg
            height: Tokens.iconLg
            Icon {
                anchors.centerIn: parent
                visible: row.icon !== ""
                name: row.icon
                filled: true
                size: Tokens.iconLg
                color: row.iconColor
            }
        }

        StyledText {
            id: labelText
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - iconSlot.width - valueText.implicitWidth - trailingRow.implicitWidth - parent.spacing * 3
            style: "bodyMd"
            color: row.labelColor
            elide: Text.ElideRight
            text: row.label
        }

        StyledText {
            id: valueText
            anchors.verticalCenter: parent.verticalCenter
            style: "monoLg"
            color: row.valueColor
            text: row.value
        }

        Row {
            id: trailingRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.space2
        }
    }
}
