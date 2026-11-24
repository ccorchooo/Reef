import QtQuick
import QtQuick.Effects
import qs.theme

// One pill of the bar (DESIGN.md §1, SURFACES.md → Bar).
// cay-height tall, radius-full, surface-container, shadow-float. Its width follows the
// content with a spatial spring, so a cay re-forms in place when its content changes.
// A cay can also grow upward (the Status cay becoming a quick menu): set `targetHeight`
// and `targetRadius`; both follow with the same spring. It grows from its bottom edge.
//
//   Cay { leftPadding: Tokens.space2; rightPadding: Tokens.space2; Row { … } }
Item {
    id: root

    default property alias content: holder.data
    property real leftPadding: Tokens.space2
    property real rightPadding: Tokens.space2
    // Width the content wants; override to drive the re-form yourself.
    property real contentWidth: holder.childrenRect.width
    readonly property real targetWidth: contentWidth + leftPadding + rightPadding
    property real targetHeight: Tokens.cayHeight
    property real targetRadius: Tokens.cayHeight / 2
    property color color: Colors.surfaceContainer
    // True while the cay is taller than the bar (grown or still shrinking back).
    readonly property bool grown: heightSpring.value > Tokens.cayHeight + 0.5

    implicitWidth: widthSpring.value
    implicitHeight: heightSpring.value

    Spring {
        id: widthSpring
        spec: Motion.spatialDefault
        target: root.targetWidth
    }
    Spring {
        id: heightSpring
        spec: Motion.spatialDefault
        target: root.targetHeight
    }
    Spring {
        id: radiusSpring
        spec: Motion.spatialDefault
        target: root.targetRadius
    }

    RectangularShadow {
        anchors.fill: bg
        radius: bg.radius
        offset.x: Colors.shadowFloat.x
        offset.y: Colors.shadowFloat.y
        blur: Colors.shadowFloat.blur
        color: Colors.shadowFloat.color
        cached: true
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.min(radiusSpring.value, height / 2, width / 2)
        color: root.color
    }

    Item {
        id: holder
        x: root.leftPadding
        width: root.width - root.leftPadding - root.rightPadding
        height: parent.height
        clip: true
    }
}
