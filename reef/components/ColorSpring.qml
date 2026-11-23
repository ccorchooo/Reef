import QtQuick
import qs.theme

// Animates a color with an effects spring (never overshoots).
//
//   ColorSpring { id: fill; target: on ? Colors.primaryContainer : Colors.surfaceContainerHigh }
//   color: fill.value
//
// Interruptible: a new target blends from whatever is on screen right now.
QtObject {
    id: root

    property var spec: Motion.effectsDefault
    property color target: "transparent"
    readonly property color value: _mix(_from, target, progress.value)

    property color _from: "transparent"
    property bool _ready: false

    function snap(c) {
        target = c;
        _from = c;
        progress.snap(1);
    }

    function _mix(a, b, t) {
        if (t >= 1)
            return b;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    onTargetChanged: {
        if (!_ready)
            return;
        _from = value;          // freeze what is visible now, then blend to the new target
        progress.snap(0);
        progress.target = 1;
    }

    Component.onCompleted: {
        _from = target;
        progress.snap(1);
        _ready = true;
    }

    property Spring _progress: Spring {
        id: progress
        spec: root.spec
    }
}
