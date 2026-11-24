import QtQuick
import qs.theme
import qs.components
import qs.modules

// One item in the Status cay's row: the clock, an icon, or an indicator. Items don't
// take clicks (a click anywhere on the row opens the control center); the Status cay
// tracks the pointer and opens an item's quick menu when it rests on it. Each item
// slides to `targetX` with spatial-default when the row re-forms around a menu.
// Keyboard: Enter or Space opens or closes the item's menu.
Item {
    id: item

    required property string screenName
    property string menu: ""                 // quick menu this item opens ("" = none)
    property string key: menu
    property string label: ""
    property real targetX: 0
    property bool hovered: false             // set by the Status cay
    default property alias content: holder.data
    readonly property bool active: menu !== "" && PanelState.barMenu(screenName) === menu

    x: xSpring.value
    implicitWidth: holder.childrenRect.width
    width: implicitWidth
    height: Tokens.cayHeight

    Spring {
        id: xSpring
        spec: Motion.spatialDefault
        target: item.targetX
    }

    activeFocusOnTab: menu !== ""
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.ignored: menu === ""
    Keys.onReturnPressed: PanelState.toggleBarMenu(menu, item.screenName)
    Keys.onSpacePressed: PanelState.toggleBarMenu(menu, item.screenName)

    Rectangle {
        anchors.centerIn: parent
        width: parent.width + Tokens.space2 * 2
        height: Tokens.cayItemSm
        radius: height / 2
        color: item.active ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        opacity: item.menu !== "" && (item.active || item.activeFocus || item.hovered) ? 1 : 0
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
}
