import QtQuick
import qs.theme
import qs.components
import qs.modules

// An icon or label inside the Status cay that opens its own quick menu
// (clock → calendar, network → Wi-Fi, volume → audio output).
Item {
    id: item
    required property string screenName
    property string menu: ""
    property string label: ""
    default property alias content: holder.data
    readonly property bool hovered: mouse.containsMouse
    readonly property bool active: PanelState.menu === menu && PanelState.screenName === item.screenName

    width: holder.childrenRect.width
    height: Tokens.cayHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: PanelState.toggle(menu, item.screenName)
    Keys.onSpacePressed: PanelState.toggle(menu, item.screenName)

    Rectangle {
        anchors.centerIn: parent
        width: parent.width + Tokens.space2 * 2
        height: Tokens.cayItemSm
        radius: height / 2
        color: item.active ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        opacity: item.active || item.activeFocus || item.hovered ? 1 : 0
        border.width: item.activeFocus ? 2 : 0
        border.color: Colors.primary
        Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } }
    }
    Item {
        id: holder
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -Tokens.space1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: PanelState.toggle(item.menu, item.screenName)
    }
}
