import QtQuick
import QtQuick.Shapes
import qs.theme

// A concave corner piece: a size×size square minus a quarter circle. Rounds the
// screen corners and joins Tide panels to the screen edge
// (SURFACES.md → Global rules).
//
// `corner` names the solid corner of the square, the one that touches both
// straight edges: "topLeft", "topRight", "bottomRight" or "bottomLeft".
//
//   EdgeFillet { corner: "bottomRight"; color: Colors.surfaceContainerLow }  // above a right-edge panel
Shape {
    id: root

    property string corner: "topLeft"
    property real size: Tokens.radiusXl
    property color color: Colors.screenCorner

    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer
    rotation: ({ topLeft: 0, topRight: 90, bottomRight: 180, bottomLeft: 270 })[corner] ?? 0

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        startX: 0
        startY: 0
        PathLine { x: root.size; y: 0 }
        PathArc {
            x: 0
            y: root.size
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
        PathLine { x: 0; y: 0 }
    }
}
