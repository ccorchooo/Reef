import QtQuick
import qs.theme
import qs.components

// A group of settings: an optional label in settings-section, then a
// surface-container-high radius-xl card holding the rows, space-4 apart.
//
//   SettingsSection { title: "Island"; SwitchRow { … } SwitchRow { … } }
Column {
    id: root

    property string title: ""
    default property alias content: rows.data

    spacing: Tokens.space2

    StyledText {
        visible: root.title !== ""
        style: "settingsSection"
        text: root.title
        Accessible.role: Accessible.Heading
    }

    Rectangle {
        width: parent.width
        height: rows.implicitHeight + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerHigh

        Column {
            id: rows
            x: Tokens.space4
            y: Tokens.space4
            width: parent.width - Tokens.space4 * 2
            spacing: Tokens.space4
        }
    }
}
