import QtQuick
import qs.theme

// An interruptible M3 Expressive spring for one number.
//
//   Spring { id: w; spec: Motion.spatialDefault; target: expanded ? 400 : 120 }
//   width: w.value
//
// Integrates x'' = -k(x - target) - c·x' with c = 2ζ√k (mass 1). Changing `target`
// mid-flight keeps the current velocity, so motion never jumps.
// Reduce motion: spatial springs snap (the caller crossfades); effects springs still run.
QtObject {
    id: root

    property var spec: Motion.spatialDefault
    property real target: 0
    property real value: target
    property real velocity: 0
    readonly property bool running: anim.running

    // Jump straight to v with no motion.
    function snap(v) {
        _snapping = true;
        anim.running = false;
        velocity = 0;
        target = v;
        value = v;
        _snapping = false;
    }

    property real _range: 1
    property bool _ready: false
    property bool _snapping: false

    onTargetChanged: {
        if (!_ready || _snapping)
            return;
        if (Motion.reduceMotion && !spec.effects) {
            snap(target);
            return;
        }
        _range = Math.max(Math.abs(target - value), 1e-6);
        anim.running = true;
    }

    Component.onCompleted: {
        value = target;
        _ready = true;
    }

    property FrameAnimation _anim: FrameAnimation {
        id: anim
        onTriggered: {
            const k = root.spec.stiffness;
            const c = 2 * root.spec.damping * Math.sqrt(k);
            // Speed setting scales time; clamp long frames so a stall doesn't explode.
            let dt = Math.min(frameTime, 1 / 30) * Motion.speed;
            let x = root.value, v = root.velocity;
            const t = root.target;
            // Fixed small sub-steps keep stiff springs (effects-fast, k=3800) stable.
            const steps = Math.max(1, Math.ceil(dt / 0.004));
            const h = dt / steps;
            for (let i = 0; i < steps; i++) {
                v += (-k * (x - t) - c * v) * h;   // semi-implicit Euler
                x += v * h;
            }
            const eps = Motion.settleEpsilon * root._range;
            if (Math.abs(x - t) < eps && Math.abs(v) < eps * 10) {
                x = t;
                v = 0;
                running = false;
            }
            root.velocity = v;
            root.value = x;
        }
    }
}
