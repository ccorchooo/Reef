import QtQuick
import qs.theme

// A Material Symbols Rounded glyph (DESIGN.md §6).
//
//   Icon { name: "wifi"; filled: Network.enabled }
//
// FILL 0 → 1 means active. It crossfades an outlined glyph into a filled one with
// effects-fast instead of animating the FILL axis: every new axis value makes Qt build a
// new font instance from the variable font, which stalls the GUI thread for well over a
// frame (the Island's tab circles ran at ~5 fps). Two fixed instances are cheap.
// opsz follows the size. Icons are decorative to screen readers; the control that holds
// one carries the label.
Item {
    id: root

    property string name: ""
    property bool filled: false
    property real size: Tokens.iconMd
    property real weight: 400
    property real grade: 0
    property color color: Colors.on.surfaceVariant
    readonly property real fill: fillSpring.value

    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true

    Spring {
        id: fillSpring
        spec: Motion.effectsFast
        target: root.filled ? 1 : 0
    }

    component Glyph: Text {
        property real fillAxis: 0
        anchors.fill: parent
        text: root.name
        color: root.color
        font.family: Type.icons
        font.pixelSize: root.size
        font.variableAxes: ({ FILL: fillAxis, wght: root.weight, GRAD: root.grade, opsz: Math.max(20, Math.min(48, root.size)) })
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
        Accessible.ignored: true
    }

    Glyph {
        fillAxis: 0
        opacity: 1 - Math.max(0, Math.min(1, root.fill))
        visible: opacity > 0.001
    }
    Glyph {
        fillAxis: 1
        opacity: Math.max(0, Math.min(1, root.fill))
        visible: opacity > 0.001
    }
}
