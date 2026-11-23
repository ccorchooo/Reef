import QtQuick
import qs.theme

// An M3E shape that morphs when `shape` changes (DESIGN.md §4, MOTION.md).
//
//   ShapeMorph { shape: on ? "pill" : "squircle"; color: Colors.primaryContainer; spec: Motion.spatialFast }
//
// Interruptible: a new shape mid-morph starts from what's on screen. Box shapes (pill,
// squircle) follow the item's size, so resizing and morphing can happen together.
// With Reduce motion or Settings → Performance → Shape morphs off, the new shape
// swaps in under a short crossfade instead.
Item {
    id: root

    property string shape: "circle"
    property color color: Colors.primary
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property var spec: Motion.spatialDefault
    readonly property bool morphing: progress.running

    // {name} or {name, radii} when a morph was interrupted (frozen blend).
    property var _from: ({ name: "circle", radii: null })
    property string _to: "circle"
    property bool _ready: false

    readonly property var _fromRadii: _from.radii ?? Shapes.sample(_from.name, width, height)
    readonly property var _toRadii: Shapes.sample(_to, width, height)
    readonly property var radii: progress.running ? Shapes.mix(_fromRadii, _toRadii, progress.value) : _toRadii

    onShapeChanged: {
        if (!_ready || shape === _to)
            return;
        if (!Motion.shapeMorphs) {
            ghost.radii = radii;
            _from = { name: shape, radii: null };
            _to = shape;
            progress.snap(1);
            swap.restart();
            return;
        }
        _from = progress.running ? { name: _to, radii: radii.slice() } : { name: _to, radii: null };
        _to = shape;
        progress.snap(0);
        progress.target = 1;
    }

    Component.onCompleted: {
        _to = shape;
        _from = { name: shape, radii: null };
        progress.snap(1);
        _ready = true;
    }

    Spring {
        id: progress
        spec: root.spec
    }

    ShapeItem {
        id: body
        anchors.fill: parent
        radii: root.radii
        color: root.color
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
    }

    // Reduce motion: the old shape fades out over the new one.
    ShapeItem {
        id: ghost
        anchors.fill: parent
        opacity: 0
        color: root.color
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        visible: opacity > 0
    }

    ParallelAnimation {
        id: swap
        NumberAnimation { target: ghost; property: "opacity"; from: 1; to: 0; duration: Motion.reducedFade }
        NumberAnimation { target: body; property: "opacity"; from: 0; to: 1; duration: Motion.reducedFade }
    }
}
