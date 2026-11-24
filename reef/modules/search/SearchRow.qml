import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.components

// One search result (screens/Search): an app icon or a glyph, a title and a subtitle.
// The keyboard-selected row sits on secondary-container; hover tints it.
Item {
    id: root

    required property var result
    property bool selected: false
    signal activated

    implicitHeight: Tokens.searchRowHeight

    Accessible.role: Accessible.ListItem
    Accessible.name: result.title + (result.subtitle ? ", " + result.subtitle : "")
    Accessible.selected: selected

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: root.selected ? Colors.secondaryContainer
            : mouse.containsMouse ? Colors.surfaceContainerHigh : Qt.alpha(Colors.surfaceContainerHigh, 0)
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radiusLg
        color: bg.value
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Tokens.space3
        anchors.rightMargin: Tokens.space3
        spacing: Tokens.space3

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.searchRowIcon
            height: Tokens.searchRowIcon

            IconImage {
                anchors.centerIn: parent
                visible: root.result.iconSource !== ""
                implicitSize: Tokens.searchRowIcon
                source: root.result.iconSource
            }
            Icon {
                anchors.centerIn: parent
                visible: root.result.icon !== ""
                name: root.result.icon
                size: Tokens.iconLg
                color: root.selected ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
            }
            // Coral's mark.
            ShapeItem {
                anchors.centerIn: parent
                visible: root.result.kind === "coral"
                width: Tokens.iconLg
                height: Tokens.iconLg
                radii: Shapes.sample("clover4", width, height)
                color: Colors.primary
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.searchRowIcon - parent.spacing

            StyledText {
                width: parent.width
                style: "searchTitle"
                elide: Text.ElideRight
                color: Colors.on.surface
                text: root.result.title
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: "bodySm"
                elide: Text.ElideRight
                color: Colors.on.surfaceVariant
                text: root.result.subtitle
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
