import QtQuick
import qs.theme
import qs.components
import qs.modules

// One item in the Status cay's row: the clock, an icon, or an indicator. Items don't
// take clicks (a click anywhere on the row opens the control center); the Status cay
// tracks the pointer and opens an item's quick menu when it rests on it. Each item
// slides to `targetX` with spatial-default when the row re-forms around a menu.
// Keyboard: Enter or Space opens or closes the item's menu.
// With the bar on the left (`vertical`) items stack: each is cay-height wide and sits at
// `targetY`.
Item {
    id: item

    required property string screenName
    property string menu: ""                 // quick menu this item opens ("" = none)
    property string key: menu
    property string label: ""
    property real targetX: 0
    property real targetY: 0
    property bool vertical: false
    property bool hovered: false             // set by the Status cay
    default property alias content: holder.data
    readonly property bool active: menu !== "" && PanelState.barMenu(screenName) === menu

    x: vertical ? 0 : xSpring.value
    y: vertical ? ySpring.value : 0
    implicitWidth: vertical ? Tokens.cayHeight : holder.childrenRect.width
    implicitHeight: vertical ? holder.childrenRect.height : Tokens.cayHeight
    width: implicitWidth
    height: implicitHeight

    Spring {
        id: xSpring
        spec: Motion.spatialDefault
        target: item.targetX
    }
    Spring {
        id: ySpring
        spec: Motion.spatialDefault
        target: item.targetY
    }

    activeFocusOnTab: menu !== ""
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.ignored: menu === ""
    Keys.onReturnPressed: PanelState.toggleBarMenu(menu, item.screenName)
    Keys.onSpacePressed: PanelState.toggleBarMenu(menu, item.screenName)

    // A circle behind an icon, a pill behind text (the clock).
    Rectangle {
        anchors.centerIn: parent
        height: item.vertical ? (item.height >= width ? item.height + Tokens.space2 * 2 : width) : Tokens.cayItemSm
        width: item.vertical ? Tokens.cayItemSm : item.width >= height ? item.width + Tokens.space2 * 2 : height
        radius: height / 2
        color: item.active ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        opacity: item.menu !== "" && (item.active || item.activeFocus || item.hovered) ? 1 : 0
        border.width: item.activeFocus ? 2 : 0
        border.color: Colors.primary
        Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } }
    }
    Item {
        id: holder
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
