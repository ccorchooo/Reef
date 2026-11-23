import QtQuick
import QtQuick.Effects
import qs.theme

// One pill of the bar (DESIGN.md §1, SURFACES.md → Bar).
// cay-height tall, radius-full, surface-container, shadow-float. Its width follows the
// content with a spatial spring, so a cay re-forms in place when its content changes.
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
    property color color: Colors.surfaceContainer

    implicitWidth: widthSpring.value
    implicitHeight: Tokens.cayHeight

    Spring {
        id: widthSpring
        spec: Motion.spatialDefault
        target: root.targetWidth
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
        radius: height / 2
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
