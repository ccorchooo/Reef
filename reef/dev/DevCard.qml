import QtQuick
import qs.theme
import qs.components

// A titled surface-container card for the dev window.
Rectangle {
    id: root

    property string title: ""
    default property alias content: body.data

    implicitHeight: col.implicitHeight + Tokens.space6 * 2
    radius: Tokens.radiusXl
    color: Colors.surfaceContainer

    Column {
        id: col
        x: Tokens.space6
        y: Tokens.space6
        width: root.width - Tokens.space6 * 2
        spacing: Tokens.space4

        StyledText {
            style: "titleMd"
            text: root.title
        }

        Column {
            id: body
            width: parent.width
            spacing: Tokens.space4
        }
    }
}
