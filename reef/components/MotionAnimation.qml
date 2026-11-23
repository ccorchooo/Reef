import QtQuick
import qs.theme

// Bezier fallback for Behaviors that can't use a Spring (MOTION.md table).
// Prefer Spring for anything that may be interrupted.
//
//   Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } }
NumberAnimation {
    property var spec: Motion.effectsDefault
    duration: Motion.duration(spec)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve(spec)
}
