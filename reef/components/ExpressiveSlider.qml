import QtQuick
import qs.theme

// The thick M3 Expressive slider (screens/ControlCenter): a filled part with its icon,
// a gap, a tall handle bar, another gap, then the track. Drag, click, scroll, or use
// the arrow keys.
//
//   ExpressiveSlider { icon: "volume_up"; label: "Volume"; value: Audio.volume; onMoved: v => Audio.setVolume(v) }
Item {
    id: root

    property real value: 0                    // 0..1
    property string icon: ""
    property string label: ""
    property real step: 0.05
    signal moved(real value)

    implicitHeight: Tokens.sliderHandleHeight

    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: label
    Keys.onLeftPressed: moved(Math.max(0, value - step))
    Keys.onRightPressed: moved(Math.min(1, value + step))
    Keys.onDownPressed: moved(Math.max(0, value - step))
    Keys.onUpPressed: moved(Math.min(1, value + step))

    readonly property real _gap: Tokens.space1
    readonly property real _usable: width - Tokens.sliderHandleWidth - _gap * 2
    readonly property real _shown: drag.pressed ? _dragValue : Math.max(0, Math.min(1, value))
    property real _dragValue: 0

    Spring {
        id: pos
        spec: Motion.spatialFast
        target: root._shown * root._usable
    }

    // Filled part
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, pos.value)
        height: Tokens.sliderHeight
        visible: width > 0.5
        color: Colors.primary
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Math.min(Tokens.radiusFillCap, width / 2)
        bottomRightRadius: Math.min(Tokens.radiusFillCap, width / 2)
        clip: true

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.space3_5
            name: root.icon
            filled: true
            size: Tokens.iconMd
            color: Colors.on.primary
        }
    }

    // Handle
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: pos.value + root._gap
        width: Tokens.sliderHandleWidth
        height: drag.pressed ? Tokens.sliderHandleHeight + Tokens.space1 : Tokens.sliderHandleHeight
        radius: width / 2
        color: Colors.primary
        border.width: root.activeFocus ? 1 : 0
        border.color: Colors.on.surface
        Behavior on height { MotionAnimation { spec: Motion.spatialFast } }
    }

    // Track
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: pos.value + root._gap * 2 + Tokens.sliderHandleWidth
        width: Math.max(0, root.width - x)
        height: Tokens.sliderHeight
        visible: width > 0.5
        color: Colors.surfaceContainerHighest
        topRightRadius: height / 2
        bottomRightRadius: height / 2
        topLeftRadius: Math.min(Tokens.radiusFillCap, width / 2)
        bottomLeftRadius: Math.min(Tokens.radiusFillCap, width / 2)

        // With the fill too short to hold it, the icon sits on the track.
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.space3_5
            visible: pos.value < Tokens.space3_5 * 2 + Tokens.iconMd
            name: root.icon
            filled: true
            size: Tokens.iconMd
            color: Colors.on.surfaceVariant
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(x) {
            return Math.max(0, Math.min(1, (x - root._gap - Tokens.sliderHandleWidth / 2) / root._usable));
        }
        onPressed: event => {
            root._dragValue = at(event.x);
            root.moved(root._dragValue);
        }
        onPositionChanged: event => {
            if (pressed) {
                root._dragValue = at(event.x);
                root.moved(root._dragValue);
            }
        }
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
