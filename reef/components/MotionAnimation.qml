import QtQuick
import qs.theme

// Bezier fallback for Behaviors that can't use a Spring (MOTION.md table).
// Prefer Spring for anything that may be interrupted.
// Reduce motion: spatial specs jump (nothing moves or overshoots); effects specs still run.
//
//   Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } }
NumberAnimation {
    property var spec: Motion.effectsDefault
    duration: Motion.reduceMotion && !spec.effects ? 0 : Motion.duration(spec)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve(spec)
}
