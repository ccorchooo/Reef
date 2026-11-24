import QtQuick
import QtQuick.Shapes
import qs.theme

// M3 Expressive wavy progress (the Island's Now tab).
// The played part is a wave that travels while `playing` and flattens when paused;
// the rest is a straight track. Click or drag to seek.
// The wave is built once (for the full width plus a wavelength) and slides inside a
// clip as wide as the played part, so playing costs a move per frame, not a new path;
// it's rebuilt only when the width or the amplitude changes.
//
//   WavyProgress { progress: Media.progress; playing: Media.playing; onSeek: f => Media.seekTo(f) }
Item {
    id: root

    property real progress: 0
    property bool playing: false
    property bool interactive: true
    property color color: Colors.islandAccent
    property color trackColor: Colors.islandTrack
    signal seek(real fraction)

    readonly property bool dragging: mouse.pressed
    property real _dragFraction: 0
    readonly property real shown: dragging ? _dragFraction : Math.max(0, Math.min(1, progress))

    implicitHeight: Tokens.waveHeight
    Accessible.role: Accessible.Slider
    Accessible.name: "Playback position"

    readonly property real _stroke: Tokens.waveStroke
    readonly property real _inset: _stroke / 2
    readonly property real _usable: Math.max(0, width - _stroke)
    readonly property real _thumbX: _inset + shown * _usable
    readonly property real _gap: Tokens.waveThumb / 2 + Tokens.space1

    property real _phase: 0

    Spring {
        id: amp
        spec: Motion.spatialDefault
        target: root.playing ? Tokens.waveAmplitude : 0
    }

    FrameAnimation {
        running: root.playing && root.visible && !Motion.reduceMotion
        onTriggered: root._phase = (root._phase + frameTime * Motion.speed * 2 * Math.PI * 1000 / Tokens.wavePeriod) % (2 * Math.PI)
    }

    readonly property real _k: 2 * Math.PI / Tokens.waveLength
    readonly property real _end: Math.max(_inset, _thumbX - _gap / 2)
    function _y(x) {
        return height / 2 + amp.value * Math.sin(_k * x - _phase);
    }

    // One static wave from x = 0 to width + a wavelength.
    readonly property var _staticWave: {
        const pts = [];
        const mid = height / 2, a = amp.value, len = width + Tokens.waveLength;
        for (let x = 0; x <= len; x += 2)
            pts.push(Qt.point(x, mid + a * Math.sin(_k * x)));
        return pts;
    }

    // The played part.
    Item {
        id: played
        x: root._inset
        width: Math.max(0, root._end - root._inset)
        height: root.height
        clip: true
        visible: root.shown > 0.002

        Shape {
            // Slides right by the phase (so it matches _y): starting a wavelength to the
            // left keeps the clip filled.
            x: root._phase / root._k - Tokens.waveLength - root._inset
            width: root.width + Tokens.waveLength
            height: parent.height
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.color
                strokeWidth: root._stroke
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root._staticWave }
            }
        }
    }
    // Round ends (the clip cuts the stroke flat).
    Repeater {
        model: played.visible ? [root._inset, root._end] : []
        Rectangle {
            required property real modelData
            width: root._stroke
            height: root._stroke
            radius: width / 2
            color: root.color
            x: modelData - width / 2
            y: root._y(modelData) - height / 2
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root._stroke
            capStyle: ShapePath.RoundCap
            startX: Math.min(root.width - root._inset, root._thumbX + root._gap)
            startY: root.height / 2
            PathLine { x: root.width - root._inset; y: root.height / 2 }
        }
    }

    Rectangle {
        width: Tokens.waveThumb
        height: Tokens.waveThumb
        radius: width / 2
        x: root._thumbX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.color
        scale: root.dragging ? 1.3 : 1
        Behavior on scale { MotionAnimation { spec: Motion.spatialFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.topMargin: -Tokens.space2
        anchors.bottomMargin: -Tokens.space2
        enabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        function fractionAt(x) {
            return Math.max(0, Math.min(1, (x - root._inset) / Math.max(1, root._usable)));
        }
        onPressed: event => root._dragFraction = fractionAt(event.x)
        onPositionChanged: event => { if (pressed) root._dragFraction = fractionAt(event.x); }
        onReleased: event => root.seek(fractionAt(event.x))
    }
}
