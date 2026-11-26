pragma Singleton
import QtQuick
import Quickshell
import qs.services

// The one place motion is defined (MOTION.md). Springs and curves come from tokens,
// scaled by Settings → Motion → Animation speed, and Reduce motion is applied here.
//
//   Spring { spec: Motion.spatialDefault; target: open ? 400 : 120 }   // preferred, interruptible
//   Behavior on opacity { MotionAnimation { spec: Motion.effectsFast } } // simple cases
Singleton {
    id: root

    readonly property bool reduceMotion: Config.options.motion.reduceMotion
    readonly property real speed: Math.max(0.1, Config.options.motion.speed)
    // Shape morphs can be turned off for performance; Reduce motion turns them off too.
    readonly property bool shapeMorphs: Config.options.performance.shapeMorphs && !reduceMotion

    readonly property var spatialFast: _spec("spatialFast")
    readonly property var spatialDefault: _spec("spatialDefault")
    readonly property var spatialSlow: _spec("spatialSlow")
    // Beyond M3E's set: a looser spring for playful hops (the Pearl, password shapes).
    readonly property var spatialBouncy: _spec("spatialBouncy")
    readonly property var effectsFast: _spec("effectsFast")
    readonly property var effectsDefault: _spec("effectsDefault")
    readonly property var effectsSlow: _spec("effectsSlow")

    // Reduce motion: spatial motion becomes a crossfade of this length (ms).
    readonly property real reducedFade: Tokens.reducedFade / speed
    readonly property real contentFadeDelay: Tokens.contentFadeDelay / speed
    readonly property real settleEpsilon: Tokens.settleEpsilon

    // Delay for the i-th item of a staggered list (ms).
    function stagger(i) {
        return Math.min(i, Tokens.staggerMax) * Tokens.staggerStep / speed;
    }

    // Fallback duration (ms) for places that can't run a spring.
    function duration(spec) {
        if (reduceMotion && !spec.effects)
            return 0;
        return spec.duration / speed;
    }

    // Easing curve list for Easing.BezierSpline.
    function curve(spec) {
        return spec.bezier.concat([1, 1]);
    }

    function _spec(name) {
        const s = Tokens.springs[name];
        return {
            name: name,
            effects: name.startsWith("effects"),
            stiffness: s.stiffness,
            damping: s.damping,
            duration: s.duration,
            bezier: s.bezier
        };
    }
}
