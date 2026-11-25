.pragma library

// Reef's color scheme generator (services/Scheme). Pure functions, no QML.
//
// Colors are handled in CIE LCh(ab): L* is M3's "tone" exactly, so the M3 tone recipe
// (primary 80 on dark, 40 on light, surfaces 4..22, …) gives the same contrast M3 does.
// Hue and chroma are LCh's, not CAM16's, so chroma numbers here are a little larger than
// matugen's for the same look. Out-of-gamut colors keep their tone and hue and lose
// chroma until they fit in sRGB.

// ── conversions ───────────────────────────────────────────────
function _lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
function _gam(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; }
function _f(t) { return t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116; }
function _fi(t) { return t * t * t > 216 / 24389 ? t * t * t : (116 * t - 16) / (24389 / 27); }
const _W = [0.95047, 1, 1.08883];

function rgbOf(hex) {
    const h = String(hex).replace("#", "");
    const s = h.length === 8 ? h.slice(2) : h;          // #AARRGGBB → RRGGBB
    return [parseInt(s.slice(0, 2), 16) / 255, parseInt(s.slice(2, 4), 16) / 255, parseInt(s.slice(4, 6), 16) / 255];
}

function hexOf(rgb) {
    return "#" + rgb.map(v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0")).join("");
}

// sRGB (0..1) → { l, c, h }
function lchOfRgb(rgb) {
    const [r, g, b] = rgb.map(_lin);
    const x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / _W[0];
    const y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    const z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / _W[2];
    const fx = _f(x), fy = _f(y), fz = _f(z);
    const L = 116 * fy - 16, A = 500 * (fx - fy), B = 200 * (fy - fz);
    let h = Math.atan2(B, A) * 180 / Math.PI;
    if (h < 0)
        h += 360;
    return { l: L, c: Math.hypot(A, B), h: h };
}

function lch(hex) {
    return lchOfRgb(rgbOf(hex));
}

// { l, c, h } → linear-light sRGB, possibly out of 0..1
function _rgbOfLch(l, c, h) {
    const A = c * Math.cos(h * Math.PI / 180), B = c * Math.sin(h * Math.PI / 180);
    const fy = (l + 16) / 116, fx = fy + A / 500, fz = fy - B / 200;
    const x = _fi(fx) * _W[0], y = l > 8 ? fy * fy * fy : l / (24389 / 27), z = _fi(fz) * _W[2];
    return [
        3.2404542 * x - 1.5371385 * y - 0.4985314 * z,
        -0.9692660 * x + 1.8760108 * y + 0.0415560 * z,
        0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    ];
}

function _inGamut(lin) {
    return lin.every(v => v >= -1e-4 && v <= 1 + 1e-4);
}

// A color at tone `l`, chroma `c`, hue `h`; chroma is cut until it fits in sRGB.
function fromLch(l, c, h) {
    l = Math.max(0, Math.min(100, l));
    let lin = _rgbOfLch(l, c, h);
    if (!_inGamut(lin)) {
        let lo = 0, hi = c;
        for (let i = 0; i < 18; i++) {
            const mid = (lo + hi) / 2;
            if (_inGamut(_rgbOfLch(l, mid, h)))
                lo = mid;
            else
                hi = mid;
        }
        lin = _rgbOfLch(l, lo, h);
    }
    return hexOf(lin.map(v => _gam(Math.max(0, Math.min(1, v)))));
}

// ── contrast ──────────────────────────────────────────────────
function luminance(hex) {
    const [r, g, b] = rgbOf(hex).map(_lin);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a, b) {
    const la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

// Moves `fg`'s tone away from `bg` (keeping hue and chroma) until they reach `min`.
function ensureContrast(fg, bg, min) {
    if (contrast(fg, bg) >= min)
        return fg;
    const f = lch(fg), lb = lch(bg).l;
    // Toward whichever end can still reach the target.
    const towardLight = contrast("#ffffff", bg) >= min && (f.l >= lb || contrast("#000000", bg) < min);
    for (let step = 1; step <= 100; step++) {
        const c = fromLch(f.l + (towardLight ? step : -step), f.c, f.h);
        if (contrast(c, bg) >= min)
            return c;
    }
    return towardLight ? "#ffffff" : "#000000";
}

// Mixes two colors in Lab (t = 0 → a, 1 → b).
function mix(a, b, t) {
    const x = lch(a), y = lch(b);
    const ax = x.c * Math.cos(x.h * Math.PI / 180), ay = x.c * Math.sin(x.h * Math.PI / 180);
    const bx = y.c * Math.cos(y.h * Math.PI / 180), by = y.c * Math.sin(y.h * Math.PI / 180);
    const A = ax + (bx - ax) * t, B = ay + (by - ay) * t;
    let h = Math.atan2(B, A) * 180 / Math.PI;
    if (h < 0)
        h += 360;
    return fromLch(x.l + (y.l - x.l) * t, Math.hypot(A, B), h);
}

function _hueDistance(a, b) {
    const d = Math.abs(a - b) % 360;
    return d > 180 ? 360 - d : d;
}

// ── wallpaper colors ──────────────────────────────────────────
// From ColorQuantizer's colors (each about an equal share of the picture), the seeds:
// one per hue family, the most common families first, each represented by its most
// colorful member. A gray picture gives its middle gray. Returns hex strings (≤ 5).
function seeds(colors) {
    const all = colors.map(c => {
        const rgb = [c.r, c.g, c.b];
        return Object.assign({ hex: hexOf(rgb) }, lchOfRgb(rgb));
    }).filter(c => c.l > 6 && c.l < 97);
    if (all.length === 0)
        return [];
    const colorful = all.filter(c => c.c >= 10);
    if (colorful.length === 0) {
        all.sort((a, b) => Math.abs(a.l - 55) - Math.abs(b.l - 55));
        return [all[0].hex];
    }
    // Hue families: 30° bins, scored by how much of the picture they cover and how vivid
    // they are; a very dark or very light member counts for less.
    const bins = {};
    for (const c of colorful) {
        const k = Math.floor(((c.h + 15) % 360) / 30);
        const w = Math.min(c.c, 70) / 70 * (1 - Math.abs(c.l - 55) / 80);
        const bin = bins[k] ?? (bins[k] = { score: 0, best: null });
        bin.score += 0.6 + w;
        const quality = c.c * (1 - Math.abs(c.l - 60) / 100);
        if (!bin.best || quality > bin.best.quality)
            bin.best = Object.assign({ quality: quality }, c);
    }
    const ranked = Object.keys(bins).map(k => bins[k]).sort((a, b) => b.score - a.score);
    const out = [];
    for (const b of ranked) {
        if (out.some(o => _hueDistance(o.h, b.best.h) < 20))
            continue;
        out.push(b.best);
        if (out.length === 5)
            break;
    }
    return out.map(c => c.hex);
}

// ── M3 schemes from a seed ────────────────────────────────────
// Chroma for each palette, by Colorfulness (LCh units). `gray` is a seed with almost no
// color, which keeps the accents quiet instead of inventing a hue.
//   p primary, s secondary, t tertiary, n surfaces, nv surface variants (outlines, text)
//   one    one accent: secondary and tertiary are quiet tones of the primary's hue
//   black  every background surface is pure black on dark (pure white on light)
const levels = {
    monochrome: { p: 0, s: 0, t: 0, n: 0, nv: 0 },
    neutral: { p: 20, s: 6, t: 9, n: 3, nv: 5, one: true },
    tinted: { p: 52, s: 22, t: 32, n: 6, nv: 10 },
    vivid: { p: 76, s: 34, t: 52, n: 9, nv: 14 },
    deep: { p: 26, s: 8, t: 11, n: 0, nv: 3, one: true, black: true }
};

const surfaceRoles = ["surface", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest"];

// The M3 tone recipe: role → [palette, dark tone, light tone]
const recipe = {
    primary: ["p", 80, 40], onPrimary: ["p", 20, 100], primaryContainer: ["p", 30, 90], onPrimaryContainer: ["p", 90, 10],
    secondary: ["s", 80, 40], onSecondary: ["s", 20, 100], secondaryContainer: ["s", 30, 90], onSecondaryContainer: ["s", 90, 10],
    tertiary: ["t", 80, 40], onTertiary: ["t", 20, 100], tertiaryContainer: ["t", 30, 90], onTertiaryContainer: ["t", 90, 10],
    error: ["e", 80, 40], onError: ["e", 20, 100], errorContainer: ["e", 30, 90], onErrorContainer: ["e", 90, 10],
    surface: ["n", 6, 98], onSurface: ["n", 90, 10], onSurfaceVariant: ["nv", 80, 30],
    surfaceContainerLowest: ["n", 4, 100], surfaceContainerLow: ["n", 10, 96], surfaceContainer: ["n", 12, 94],
    surfaceContainerHigh: ["n", 17, 92], surfaceContainerHighest: ["n", 22, 90],
    outline: ["nv", 60, 50], outlineVariant: ["nv", 30, 80],
    inverseSurface: ["n", 90, 20], inverseOnSurface: ["n", 20, 95], inversePrimary: ["p", 40, 80]
};

// seed: hex; tertiarySeed: hex or "" (a second wallpaper color for the tertiary accent);
// colorfulness: a key of `levels`. Returns { dark: { role: hex }, light: { … } }.
function generate(seed, tertiarySeed, colorfulness) {
    const s = lch(seed);
    const lv = levels[colorfulness] ?? levels.tinted;
    const gray = s.c < 8;
    const k = gray ? s.c / 8 : 1;          // a pure gray gets no hue at all
    // Vivid keeps a vivid seed's own strength.
    const keep = colorfulness === "vivid";
    const p = keep ? Math.max(lv.p, Math.min(s.c, 110)) * k : lv.p * k;
    let th = lv.one ? s.h : (s.h + 60) % 360;
    if (tertiarySeed && !lv.one) {
        const t = lch(tertiarySeed);
        if (t.c >= 12 && _hueDistance(t.h, s.h) >= 35)
            th = t.h;
    }
    const pal = {
        p: { h: s.h, c: p },
        s: { h: s.h, c: lv.s * k },
        t: { h: th, c: lv.t * (gray ? k : 1) },
        n: { h: s.h, c: lv.n * k },
        nv: { h: s.h, c: lv.nv * k },
        e: { h: 28, c: colorfulness === "monochrome" ? 0 : 80 }
    };
    const out = { dark: {}, light: {} };
    for (const role of Object.keys(recipe)) {
        const [key, dt, lt] = recipe[role];
        out.dark[role] = fromLch(dt, pal[key].c, pal[key].h);
        out.light[role] = fromLch(lt, pal[key].c, pal[key].h);
    }
    if (lv.black) {
        for (const role of surfaceRoles) {
            out.dark[role] = "#000000";
            out.light[role] = "#ffffff";
        }
    }
    return out;
}

// ── classic palettes ──────────────────────────────────────────
// base: { surface, surfaceContainer…, onSurface, onSurfaceVariant, outline, outlineVariant,
// primary, secondary, tertiary, error } for one mode (Tokens.palettes[id].dark/light).
function classic(base, dark) {
    const r = Object.assign({}, base);
    // Text on every surface reads at 4.5:1; accents stand out from the cays at 3:1.
    r.onSurface = ensureContrast(r.onSurface, r.surfaceContainerHighest, 4.5);
    r.onSurfaceVariant = ensureContrast(r.onSurfaceVariant, r.surfaceContainerHigh, 4.5);
    for (const a of ["primary", "secondary", "tertiary", "error"]) {
        r[a] = ensureContrast(r[a], r.surfaceContainer, 3);
        const on = "on" + a[0].toUpperCase() + a.slice(1);
        const pick = contrast(r.surfaceContainerLowest, r[a]) >= contrast(r.onSurface, r[a]) ? r.surfaceContainerLowest : r.onSurface;
        r[on] = ensureContrast(pick, r[a], 4.5);
        const container = dark ? mix(r.surfaceContainer, r[a], 0.32) : mix(r.surface, r[a], 0.22);
        r[a + "Container"] = container;
        r[on + "Container"] = ensureContrast(mix(r[a], r.onSurface, dark ? 0.4 : 0.5), container, 4.5);
    }
    r.inverseSurface = r.onSurface;
    r.inverseOnSurface = ensureContrast(r.surfaceContainer, r.inverseSurface, 4.5);
    const p = lch(r.primary);
    r.inversePrimary = ensureContrast(fromLch(dark ? 40 : 80, p.c, p.h), r.inverseSurface, 3);
    return r;
}
