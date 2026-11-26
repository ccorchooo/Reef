pragma Singleton
import QtQuick
import Quickshell

// The M3 Expressive shape library (DESIGN.md §4), as polar radius functions.
//
// Every shape is star-shaped around its center, so it can be described by its radius at
// N evenly spaced angles. Two shapes with the same N morph by blending radii angle by
// angle; a spatial spring drives the blend (see components/ShapeMorph.qml).
//
// "Fit" shapes (circle, cookies, …) sit in the largest centered square of the box.
// "Box" shapes (squircle, pill) fill the whole box, so a circle can morph into a wide pill.
Singleton {
    id: root

    readonly property int samples: 144

    // Geometry of each shape. Wave shapes are fitted to the mockups (design/mockups/html,
    // rms error < 0.4%): r = 1 - depth + depth·((1 + cos(n·θ)) / 2)^p.
    // p = 1 is a pure cosine scallop; p < 1 gives round lobes with pinched valleys
    // (clover, flower); p > 1 gives pointed tips. rot is in degrees, 0 = a lobe at the top.
    // Polygons: n sides, round = corner smoothing (fraction of a turn), stretch = x squash.
    readonly property var defs: ({
            circle:     { kind: "circle" },
            cookie4:    { kind: "wave", n: 4,  depth: 0.27, p: 1 },
            cookie6:    { kind: "wave", n: 6,  depth: 0.17, p: 1,   rot: 30 },
            cookie9:    { kind: "wave", n: 9,  depth: 0.14, p: 1,   rot: 10 },
            cookie12:   { kind: "wave", n: 12, depth: 0.10, p: 1 },
            clover4:    { kind: "wave", n: 4,  depth: 0.30, p: 0.3, round: 0.01 },
            clover8:    { kind: "wave", n: 8,  depth: 0.22, p: 0.4, round: 0.01 },
            sunny:      { kind: "wave", n: 8,  depth: 0.23, p: 1 },
            verySunny:  { kind: "wave", n: 8,  depth: 0.32, p: 1.6 },
            flower:     { kind: "wave", n: 6,  depth: 0.25, p: 0.5, rot: 30, round: 0.01 },
            pentagon:   { kind: "polygon", n: 5, round: 0.16 },
            gem:        { kind: "polygon", n: 6, round: 0.14, stretch: 0.86, rot: 90 },
            triangle:   { kind: "polygon", n: 3, round: 0.22 },
            squircle:   { kind: "rrect", radius: "lg" },
            pill:       { kind: "rrect", radius: "full" }
        })

    readonly property var names: Object.keys(defs)
    // DESIGN.md §4 / Lock mockup: the sequence typed password characters take.
    // The shapes Settings offers for the clock and the Pearl, in order.
    readonly property var choices: [
        { value: "circle", label: "Circle" },
        { value: "squircle", label: "Squircle" },
        { value: "cookie4", label: "Cookie" },
        { value: "cookie9", label: "Scallop" },
        { value: "cookie12", label: "Gear" },
        { value: "sunny", label: "Sunny" },
        { value: "flower", label: "Flower" },
        { value: "clover8", label: "Clover" },
        { value: "pentagon", label: "Pentagon" }
    ]

    readonly property var passwordSequence: ["circle", "cookie4", "clover4", "sunny", "flower", "pentagon", "gem", "cookie6", "cookie9", "verySunny"]

    // Radii in pixels for `name` drawn in a w×h box, at angles starting from the top, clockwise.
    function sample(name, w, h, n) {
        n = n ?? samples;
        const d = defs[name] ?? defs.circle;
        const out = new Array(n);
        const fit = Math.min(w, h) / 2;
        if (d.kind === "rrect") {
            const r = d.radius === "full" ? Math.min(w, h) / 2 : Math.min(Tokens.radiusLg, Math.min(w, h) / 2);
            for (let i = 0; i < n; i++)
                out[i] = _rrect(_angle(i, n), w / 2, h / 2, r);
            return out;
        }
        for (let i = 0; i < n; i++)
            out[i] = _unit(d, _angle(i, n));
        if (d.round)
            _smooth(out, d.round);
        let max = 0;
        for (let i = 0; i < n; i++)
            max = Math.max(max, out[i]);
        for (let i = 0; i < n; i++)
            out[i] = out[i] / max * fit;
        return out;
    }

    // Blend two radius arrays. t may overshoot 0..1 (spring bounce).
    function mix(a, b, t) {
        const out = new Array(b.length);
        for (let i = 0; i < b.length; i++)
            out[i] = Math.max(0, a[i] + (b[i] - a[i]) * t);
        return out;
    }

    // Closed polyline points for a radius array, centered in a w×h box.
    function points(radii, w, h) {
        const n = radii.length, pts = new Array(n + 1);
        for (let i = 0; i < n; i++) {
            const a = _angle(i, n);
            pts[i] = Qt.point(w / 2 + Math.cos(a) * radii[i], h / 2 + Math.sin(a) * radii[i]);
        }
        pts[n] = pts[0];
        return pts;
    }

    function _angle(i, n) {
        return -Math.PI / 2 + i * 2 * Math.PI / n;
    }

    // Radius of a unit "fit" shape at angle a (before normalizing).
    // `stretch` squashes the shape horizontally: map the ray into the unsquashed shape.
    function _unit(d, a) {
        if (!d.stretch)
            return _base(d, a);
        const b = Math.atan2(Math.sin(a), Math.cos(a) / d.stretch);
        return _base(d, b) * Math.hypot(d.stretch * Math.cos(b), Math.sin(b));
    }

    function _base(d, a) {
        const rot = (d.rot ?? 0) * Math.PI / 180;
        const t = a + Math.PI / 2 - rot;   // 0 at the top
        switch (d.kind) {
        case "circle":
            return 1;
        case "wave":
            return 1 - d.depth + d.depth * Math.pow((1 + Math.cos(d.n * t)) / 2, d.p);
        case "polygon": {
            const seg = 2 * Math.PI / d.n;
            const local = ((t % seg) + seg) % seg - seg / 2;
            return Math.cos(Math.PI / d.n) / Math.cos(local);
        }
        }
        return 1;
    }

    // Distance from the center to a rounded rectangle along angle a.
    function _rrect(a, hw, hh, r) {
        const cx = Math.cos(a), cy = Math.sin(a);
        const ax = Math.abs(cx), ay = Math.abs(cy);
        let t = Math.min(ax > 1e-9 ? hw / ax : Infinity, ay > 1e-9 ? hh / ay : Infinity);
        const px = ax * t, py = ay * t;
        if (px > hw - r && py > hh - r) {
            // hit a corner: intersect with the corner circle
            const ccx = hw - r, ccy = hh - r;
            const dc = ax * ccx + ay * ccy;
            const disc = dc * dc - (ccx * ccx + ccy * ccy) + r * r;
            t = dc + Math.sqrt(Math.max(0, disc));
        }
        return t;
    }

    // Circular moving average: rounds polygon corners. `amount` is a fraction of a turn per side.
    function _smooth(arr, amount) {
        const n = arr.length;
        const k = Math.max(1, Math.round(n * amount / 4));
        const src = arr.slice();
        for (let pass = 0; pass < 2; pass++) {
            for (let i = 0; i < n; i++) {
                let s = 0;
                for (let j = -k; j <= k; j++)
                    s += src[(i + j + n) % n];
                arr[i] = s / (2 * k + 1);
            }
            for (let i = 0; i < n; i++)
                src[i] = arr[i];
        }
    }
}
