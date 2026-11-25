import QtQuick
import qs.theme
import qs.services

// A round analog clock (screens/PowerActions; later a desktop widget). A
// surface-container-high face, twelve on-surface-variant ticks, an on-surface hour hand,
// a primary minute hand and a primary dot at the center. Sizes are for a 260px face
// (power-clock-size) and scale with `size`.
//
//   AnalogClock { size: Tokens.powerClockSize }
Item {
    id: root

    property real size: Tokens.powerClockSize
    readonly property real k: size / Tokens.powerClockSize
    readonly property date now: Time.now
    readonly property real minuteAngle: now.getMinutes() * 6
    readonly property real hourAngle: (now.getHours() % 12) * 30 + now.getMinutes() / 2

    implicitWidth: size
    implicitHeight: size
    Accessible.role: Accessible.Graphic
    Accessible.name: "Clock, " + Time.time

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Colors.surfaceContainerHigh
    }

    // Ticks: each a rounded bar at the top, turned about the center.
    Repeater {
        model: 12
        Item {
            required property int index
            anchors.fill: parent
            rotation: index * 30
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Tokens.clockTickInset * root.k
                width: Tokens.clockTick * root.k
                height: Tokens.clockTickLength * root.k
                radius: width / 2
                color: Colors.on.surfaceVariant
            }
        }
    }

    component Hand: Item {
        id: hand
        property real angle: 0
        property real length: 0
        property real stroke: 0
        property color color
        anchors.fill: parent
        rotation: angle
        // Round caps: half a stroke past the tip.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - hand.length - hand.stroke / 2
            width: hand.stroke
            height: hand.length + hand.stroke
            radius: width / 2
            color: hand.color
        }
    }

    Hand {
        angle: root.hourAngle
        length: Tokens.clockHourLength * root.k
        stroke: Tokens.clockHourHand * root.k
        color: Colors.on.surface
    }
    Hand {
        angle: root.minuteAngle
        length: Tokens.clockMinuteLength * root.k
        stroke: Tokens.clockMinuteHand * root.k
        color: Colors.primary
    }

    Rectangle {
        anchors.centerIn: parent
        width: Tokens.clockCenter * root.k
        height: width
        radius: width / 2
        color: Colors.primary
    }
}
