import QtQuick
import QtQuick.Shapes
import qs.theme

// M3 Expressive wavy progress (the Island's Now tab).
// The played part is a wave that travels while `playing` and flattens when paused;
// the rest is a straight track. Click or drag to seek.
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

    readonly property var _wave: {
        const pts = [];
        const end = Math.max(_inset, _thumbX - _gap / 2);
        const mid = height / 2, a = amp.value, k = 2 * Math.PI / Tokens.waveLength;
        for (let x = _inset; x < end; x += 2)
            pts.push(Qt.point(x, mid + a * Math.sin(k * x - _phase)));
        pts.push(Qt.point(end, mid + a * Math.sin(k * end - _phase)));
        return pts;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root._stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.shown > 0.002 ? root._wave : [] }
        }

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
