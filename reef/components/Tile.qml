import QtQuick
import qs.theme

// A quick toggle (SURFACES.md → Control center; MOTION.md → Toggle on).
// Off: a squircle (radius-tile) on surface-container-high. On: morphs to a pill
// (spatial-fast), fills with primary-container (effects-default), icon FILL 0→1
// (effects-fast). Wide tiles show a label and a status line.
// Click toggles; right-click (or Menu key) opens its menu if it has one.
// Inside a ButtonGroup it takes `span` cells, and pressing it widens it while its
// neighbours make room (the Pixel press), then it morphs to its new shape.
//
//   Tile { icon: "wifi"; label: "Wi-Fi"; sublabel: Network.shortLabel; checked: …; onToggled: … }
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool checked: false
    property bool wide: false
    property bool hasMenu: false
    property bool enabledState: true
    property int span: wide ? 2 : 1
    readonly property bool pressed: mouse.pressed
    signal toggled
    signal menuRequested

    implicitHeight: Tokens.tileHeight

    // In a ButtonGroup, the group sets the width (and the press widening).
    readonly property bool grouped: !!parent && parent.widthOf !== undefined
    Spring {
        id: widthSpring
        spec: Motion.spatialFast
        target: root.grouped ? root.parent.widthOf(root) : root.implicitWidth
    }
    width: grouped ? widthSpring.value : implicitWidth
    onPressedChanged: {
        if (!grouped)
            return;
        if (pressed)
            parent.pressedItem = root;
        else if (parent.pressedItem === root)
            parent.pressedItem = null;
    }
    opacity: enabledState ? 1 : Tokens.disabledOpacity

    activeFocusOnTab: enabledState
    Accessible.role: Accessible.CheckBox
    Accessible.name: label + (sublabel ? ", " + sublabel : "")
    Accessible.checked: checked
    Keys.onReturnPressed: if (enabledState) toggled()
    Keys.onSpacePressed: if (enabledState) toggled()
    Keys.onMenuPressed: if (hasMenu) menuRequested()

    readonly property color contentColor: checked ? Colors.on.primaryContainer : Colors.on.surface

    Spring {
        id: corner
        spec: Motion.spatialFast
        target: mouse.pressed ? Tokens.radiusMd : root.checked ? root.height / 2 : Tokens.radiusTile
    }
    ColorSpring {
        id: fill
        spec: Motion.effectsDefault
        target: root.checked ? Colors.primaryContainer : Colors.surfaceContainerHigh
    }

    Rectangle {
        anchors.fill: parent
        radius: corner.value
        color: fill.value
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary

        // Hover state layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.contentColor
            opacity: mouse.pressed ? Tokens.statePressedOpacity : mouse.containsMouse ? Tokens.stateHoverOpacity : 0
            Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: root.wide ? undefined : parent.horizontalCenter
        x: root.wide ? Tokens.tilePadding : 0
        width: root.wide ? root.width - Tokens.tilePadding * 2 : implicitWidth
        spacing: Tokens.space3

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: Tokens.iconLg
            filled: root.checked
            color: root.contentColor
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.wide
            width: parent.width - Tokens.iconLg - parent.spacing

            StyledText {
                width: parent.width
                style: "tileLabel"
                elide: Text.ElideRight
                color: root.contentColor
                text: root.label
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: "tileSublabel"
                elide: Text.ElideRight
                color: root.checked ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                text: root.sublabel
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabledState
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.hasMenu)
                    root.menuRequested();
            } else {
                root.toggled();
            }
        }
    }
}
