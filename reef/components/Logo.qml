import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.theme

// The Reef mark, drawn from assets/logo/reef-mark-mono.svg and colored with a token
// (DESIGN.md §7: primary on surfaces, on-island in the Island, on-primary-container
// on the Navigator's home button). Minimum size 16px.
//
//   Logo { size: Tokens.iconSm; color: Colors.on.primaryContainer }
Item {
    id: root

    property real size: Tokens.iconMd
    property color color: Colors.primary
    readonly property real viewBox: 96

    implicitWidth: size
    implicitHeight: size
    Accessible.role: Accessible.Graphic
    Accessible.name: "Reef"

    FileView {
        id: svg
        path: Quickshell.shellPath("assets/logo/reef-mark-mono.svg")
        blockLoading: true
    }

    readonly property string pathData: (svg.text().match(/\sd="([^"]+)"/) ?? ["", ""])[1]

    Shape {
        width: root.viewBox
        height: root.viewBox
        scale: Math.max(root.size, 16) / root.viewBox
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            fillRule: ShapePath.WindingFill
            PathSvg { path: root.pathData }
        }
    }
}
