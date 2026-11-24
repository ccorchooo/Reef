import QtQuick
import qs.theme

// A row in a quick menu (networks, devices, outputs). The selected/connected row
// sits on primary-container (screens/QuickMenus). Rows stay plain rounded rectangles.
//
//   ListRow { icon: "wifi"; title: "Home"; subtitle: "Connected"; selected: true; trailingIcon: "check" }
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property string trailingIcon: ""
    default property alias extra: extraHolder.data
    signal clicked

    implicitHeight: Tokens.listRowHeight + extraHolder.childrenRect.height

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: title + (subtitle ? ", " + subtitle : "")
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    readonly property color fg: selected ? Colors.on.primaryContainer : Colors.on.surface

    ColorSpring {
        id: bg
        spec: Motion.effectsDefault
        target: root.selected ? Colors.primaryContainer : mouse.containsMouse ? Colors.surfaceContainerHigh : Qt.alpha(Colors.surfaceContainerHigh, 0)
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radiusLg
        color: bg.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary
    }

    Row {
        x: Tokens.space3
        width: parent.width - Tokens.space3 * 2
        height: Tokens.listRowHeight
        spacing: Tokens.space3

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            filled: root.selected
            size: Tokens.iconMd
            color: root.fg
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.iconMd - trailing.width - parent.spacing * 2

            StyledText {
                width: parent.width
                style: "tileLabel"
                elide: Text.ElideRight
                color: root.fg
                text: root.title
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: "tileSublabel"
                elide: Text.ElideRight
                color: root.selected ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                text: root.subtitle
            }
        }

        Icon {
            id: trailing
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailingIcon !== ""
            width: visible ? Tokens.iconSm : 0
            name: root.trailingIcon
            size: root.selected ? Tokens.iconSm : Tokens.iconXs
            color: root.selected ? Colors.on.primaryContainer : Colors.on.surfaceVariant
        }
    }

    MouseArea {
        id: mouse
        width: parent.width
        height: Tokens.listRowHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // Extra content under the row (a password field).
    Item {
        id: extraHolder
        y: Tokens.listRowHeight
        x: Tokens.space3
        width: parent.width - Tokens.space3 * 2
        height: childrenRect.height
    }
}
