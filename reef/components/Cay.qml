import QtQuick
import QtQuick.Effects
import qs.theme

// One pill of the bar (DESIGN.md §1, SURFACES.md → Bar).
// cay-height tall, radius-full, surface-container, shadow-float. Its width follows the
// content with a spatial spring, so a cay re-forms in place when its content changes.
// A cay can also grow upward (the Status cay becoming a quick menu): set `targetHeight`
// and `targetRadius`; both follow with the same spring. It grows from its bottom edge.
// With the bar on the left a cay is `vertical`: cay-height wide, its height following the
// content, and leftPadding/rightPadding become the top and bottom padding.
//
//   Cay { leftPadding: Tokens.space2; rightPadding: Tokens.space2; Row { … } }
Item {
    id: root

    default property alias content: holder.data
    property bool vertical: false
    property real leftPadding: Tokens.space2
    property real rightPadding: Tokens.space2
    // Size the content wants along the bar; override to drive the re-form yourself.
    property real contentWidth: holder.childrenRect.width
    property real contentHeight: holder.childrenRect.height
    property real targetWidth: vertical ? Tokens.cayHeight : contentWidth + leftPadding + rightPadding
    property real targetHeight: vertical ? contentHeight + leftPadding + rightPadding : Tokens.cayHeight
    property real targetRadius: Tokens.cayHeight / 2
    // Clip the content to the area inside the paddings (off when items draw past it,
    // like the Status cay's hover circles).
    property bool clipContent: true
    property color color: Colors.surfaceContainer
    // True while the cay is bigger than the bar (grown or still shrinking back).
    readonly property bool grown: vertical ? widthSpring.value > Tokens.cayHeight + 0.5 : heightSpring.value > Tokens.cayHeight + 0.5

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
        x: root.vertical ? 0 : root.leftPadding
        y: root.vertical ? root.leftPadding : 0
        width: root.vertical ? root.width : root.width - root.leftPadding - root.rightPadding
        height: root.vertical ? root.height - root.leftPadding - root.rightPadding : root.height
        clip: root.clipContent
    }
}
