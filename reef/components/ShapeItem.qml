import QtQuick
import QtQuick.Shapes
import qs.theme

// Draws one radius array from Shapes (see ShapeMorph for the animated version).
//
//   ShapeItem { width: 48; height: 48; radii: Shapes.sample("cookie9", width, height); color: Colors.primary }
Shape {
    id: root

    property var radii: Shapes.sample("circle", width, height)
    property color color: Colors.primary
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin
        PathPolyline {
            path: root.width > 0 && root.height > 0 ? Shapes.points(root.radii, root.width, root.height) : []
        }
    }
}
