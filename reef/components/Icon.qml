import QtQuick
import qs.theme

// A Material Symbols Rounded glyph (DESIGN.md §6).
//
//   Icon { name: "wifi"; filled: Network.enabled }
//
// FILL 0 → 1 means active and animates with effects-fast. opsz follows the size.
// Icons are decorative to screen readers; the control that holds one carries the label.
Text {
    id: root

    property string name: ""
    property bool filled: false
    property real size: Tokens.iconMd
    property real weight: 400
    property real grade: 0
    readonly property real fill: fillSpring.value

    text: name
    color: Colors.on.surfaceVariant
    font.family: Type.icons
    font.pixelSize: size
    font.variableAxes: ({ FILL: fill, wght: weight, GRAD: grade, opsz: Math.max(20, Math.min(48, size)) })
    width: size
    height: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    Accessible.ignored: true

    Spring {
        id: fillSpring
        spec: Motion.effectsFast
        target: root.filled ? 1 : 0
    }
}
