import QtQuick
import qs.theme

// Text in one of Reef's type styles.
//
//   StyledText { style: "labelLg"; text: "Do not disturb" }
//   StyledText { style: "numeralXl"; rond: 100; text: "09:41" }
//
// `weight`, `rond` and `wdth` drive the variable axes and can be animated
// (DESIGN.md §5: wght on press, ROND on playful surfaces, wdth for tight numerals).
Text {
    id: root

    property string style: "bodyMd"
    property real weight: Type.spec(style).weight
    property real rond: 0
    property real wdth: 100

    color: Colors.on.surface
    font.family: Type.family(style)
    font.pixelSize: Type.size(style)
    font.letterSpacing: Type.spec(style).letterSpacing * Tokens.textScale
    font.weight: Math.max(1, Math.min(1000, Math.round(weight)))
    font.variableAxes: ({ wght: weight, ROND: rond, wdth: wdth })
    lineHeight: Type.lineHeight(style)
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
