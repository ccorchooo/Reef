import QtQuick
import qs.theme

// A section of a Tide panel (SURFACES.md: sections sit on cards, never dividers).
// surface-container, radius-card (24px), space-3-5 padding, space-2-5 between rows.
//
//   Card { title: "Quick toggles"; Grid { … } }
Rectangle {
    id: root

    property string title: ""
    // Items placed at the end of the header row (e.g. a "Clear all" chip).
    property alias header: headerExtras.data
    default property alias content: body.data
    property real spacing: Tokens.space2_5

    color: Colors.surfaceContainer
    radius: Tokens.radiusCard
    implicitHeight: column.implicitHeight + Tokens.space3_5 * 2

    Column {
        id: column
        x: Tokens.space3_5
        y: Tokens.space3_5
        width: root.width - Tokens.space3_5 * 2
        spacing: root.spacing

        Item {
            width: parent.width
            height: Math.max(Tokens.chipHeight, titleText.implicitHeight)
            visible: root.title !== ""

            StyledText {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                style: "cardTitle"
                text: root.title
                Accessible.role: Accessible.Heading
            }
            Row {
                id: headerExtras
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space2
            }
        }

        Column {
            id: body
            width: parent.width
            // A header-only card (edit mode's "Edit mode · Done") has no gap below it.
            visible: children.length > 0
            spacing: root.spacing
        }
    }
}
