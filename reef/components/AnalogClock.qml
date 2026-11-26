import QtQuick
import Quickshell
import qs.theme
import qs.services

// A round analog clock (screens/PowerActions; the clock home widget). By default a
// surface-container-high circle, twelve on-surface-variant ticks, an on-surface hour hand,
// a primary minute hand and a primary dot at the center. Sizes are for a 260px face
// (power-clock-size) and scale with `size`.
//
// The home widget sets the rest from Settings → Widgets → Clock:
//   shape    any Shapes name (circle, squircle, cookie9, sunny, …)
//   numbers  none | quarters (12 3 6 9) | all (1–12) | hour (the current hour, large,
//            behind the hands; decorative, so it sits at clock-backdrop opacity)
//   ticks    hour ticks around the edge
//   seconds  a thin second hand (the clock then ticks every second)
//   tone     surface | primary | secondary | tertiary: the face's container color;
//            island: black with island inks (inside the Pearl)
//   face     false draws only the hands, ticks and numerals (the Pearl is the face)
//
//   AnalogClock { size: Tokens.powerClockSize }
Item {
    id: root

    property real size: Tokens.powerClockSize
    property string shape: "circle"
    property string numbers: "none"
    property bool ticks: true
    property bool seconds: false
    property string tone: "surface"
    property bool face: true

    readonly property real k: size / Tokens.powerClockSize
    readonly property date now: seconds ? secondClock.date : Time.now
    readonly property real minuteAngle: now.getMinutes() * 6 + (seconds ? now.getSeconds() / 10 : 0)
    readonly property real hourAngle: (now.getHours() % 12) * 30 + now.getMinutes() / 2
    readonly property real secondAngle: now.getSeconds() * 6

    // Colors for the face's tone.
    readonly property color faceColor: tone === "island" ? Colors.island
        : tone === "primary" ? Colors.primaryContainer
        : tone === "secondary" ? Colors.secondaryContainer
        : tone === "tertiary" ? Colors.tertiaryContainer : Colors.surfaceContainerHigh
    readonly property color inkColor: tone === "island" ? Colors.on.island
        : tone === "primary" ? Colors.on.primaryContainer
        : tone === "secondary" ? Colors.on.secondaryContainer
        : tone === "tertiary" ? Colors.on.tertiaryContainer : Colors.on.surface
    readonly property color softInkColor: tone === "surface" ? Colors.on.surfaceVariant
        : tone === "island" ? Colors.on.islandVariant : inkColor
    readonly property color accentColor: tone === "island" ? Colors.islandAccent
        : tone === "tertiary" ? Colors.tertiary : Colors.primary
    readonly property color secondColor: tone === "tertiary" ? Colors.primary : Colors.tertiary

    // Wavy shapes and polygons dip inward; ticks and numerals move in by the dip.
    readonly property var _def: Shapes.defs[shape] ?? Shapes.defs.circle
    readonly property real dip: (_def.kind === "polygon" ? 1 - Math.cos(Math.PI / _def.n) : _def.depth ?? 0) * size / 2
    readonly property real _numeralInset: (ticks ? Tokens.clockNumeralInsetTicks : Tokens.clockNumeralInset) * k + dip

    implicitWidth: size
    implicitHeight: size
    Accessible.role: Accessible.Graphic
    Accessible.name: "Clock, " + Time.time

    SystemClock {
        id: secondClock
        precision: SystemClock.Seconds
        enabled: root.seconds && root.visible
    }

    // Face
    Rectangle {
        anchors.fill: parent
        visible: root.face && root.shape === "circle"
        radius: width / 2
        color: root.faceColor
    }
    ShapeItem {
        anchors.fill: parent
        visible: root.face && root.shape !== "circle"
        radii: visible ? Shapes.sample(root.shape, width, height) : []
        color: root.faceColor
    }

    // The current hour, large, behind everything else.
    StyledText {
        anchors.centerIn: parent
        visible: root.numbers === "hour"
        style: "clockBackdrop"
        font.pixelSize: Type.size("clockBackdrop") * root.k
        font.letterSpacing: Type.spec("clockBackdrop").letterSpacing * root.k
        color: root.inkColor
        opacity: Tokens.clockBackdropOpacity
        text: String(root.now.getHours() % 12 || 12)
        Accessible.ignored: true
    }

    // Ticks: each a rounded bar at the top, turned about the center.
    Repeater {
        model: root.ticks ? 12 : 0
        Item {
            required property int index
            anchors.fill: parent
            rotation: index * 30
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Tokens.clockTickInset * root.k + root.dip
                width: Tokens.clockTick * root.k
                height: Tokens.clockTickLength * root.k
                radius: width / 2
                color: root.softInkColor
            }
        }
    }

    // Hour numerals, upright, on a circle inside the ticks.
    Repeater {
        model: root.numbers === "all" ? [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            : root.numbers === "quarters" ? [12, 3, 6, 9] : []
        StyledText {
            required property int modelData
            readonly property real angle: (modelData % 12) * 30 * Math.PI / 180
            readonly property real r: root.size / 2 - root._numeralInset
            x: root.size / 2 + Math.sin(angle) * r - width / 2
            y: root.size / 2 - Math.cos(angle) * r - height / 2
            style: "clockNumeral"
            font.pixelSize: Type.size("clockNumeral") * root.k
            color: root.softInkColor
            text: String(modelData)
            Accessible.ignored: true
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
        color: root.inkColor
    }
    Hand {
        angle: root.minuteAngle
        length: Tokens.clockMinuteLength * root.k
        stroke: Tokens.clockMinuteHand * root.k
        color: root.accentColor
    }
    Hand {
        visible: root.seconds
        angle: root.secondAngle
        length: Tokens.clockSecondLength * root.k
        stroke: Tokens.clockSecondHand * root.k
        color: root.secondColor
    }

    Rectangle {
        anchors.centerIn: parent
        width: Tokens.clockCenter * root.k
        height: width
        radius: width / 2
        color: root.accentColor
    }
}
