import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.components

// Rounds the display (SURFACES.md → Global rules): four concave radius-xl pieces on an
// overlay layer that takes no input and reserves no space.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-corners"
    mask: Region {}

    EdgeFillet { corner: "topLeft"; anchors.top: parent.top; anchors.left: parent.left }
    EdgeFillet { corner: "topRight"; anchors.top: parent.top; anchors.right: parent.right }
    EdgeFillet { corner: "bottomRight"; anchors.bottom: parent.bottom; anchors.right: parent.right }
    EdgeFillet { corner: "bottomLeft"; anchors.bottom: parent.bottom; anchors.left: parent.left }
}
