pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.components

// Live M3 color roles: Colors.primary, Colors.surfaceContainer, Colors.island, …
// (role properties come from the generated ColorRoles base type).
//
// Source: the matugen scheme from services/Scheme for the current light/dark mode,
// or the reference scheme in tokens.json when there is none. The Island roles and
// scrim are always the token values. Any change crossfades with effects-slow.
ColorRoles {
    id: root

    // "dark" or "light" after resolving Auto.
    readonly property string mode: {
        const t = Config.options.look.theme;
        if (t !== "auto")
            return t;
        const now = clock.hours * 60 + clock.minutes;
        const toMin = s => { const p = s.split(":"); return (+p[0]) * 60 + (+p[1] || 0); };
        const light = toMin(Config.options.look.autoLightAt), dark = toMin(Config.options.look.autoDarkAt);
        const isLight = light <= dark ? (now >= light && now < dark) : (now >= light || now < dark);
        return isLight ? "light" : "dark";
    }
    readonly property bool dark: mode === "dark"
    // Reference theme id (tokens.json) for the fallback, island roles and shadows.
    readonly property string themeId: mode + (Config.options.look.colorfulness === "neutral" ? "-neutral" : "")
    readonly property bool fromWallpaper: Scheme.scheme !== null

    readonly property var shadowIsland: Tokens.shadows.shadowIsland[themeId]
    readonly property var shadowFloat: Tokens.shadows.shadowFloat[themeId]
    readonly property var shadowToast: Tokens.shadows.shadowToast[themeId]
    readonly property var shadowMenu: Tokens.shadows.shadowMenu[themeId]
    readonly property var shadowDialog: Tokens.shadows.shadowDialog[themeId]

    // Pick a role by token name at runtime (dev window, settings previews).
    function role(name) {
        return roles[name] ?? "transparent";
    }

    // The scheme we're heading to: reference first, then generated roles over it.
    readonly property var _target: {
        const ref = Tokens.referenceSchemes[themeId];
        const gen = Scheme.scheme ? Scheme.scheme[mode] : null;
        const out = {};
        for (const k of Object.keys(ref))
            out[k] = (gen && gen[k] && !Tokens.fixedRoles.includes(k)) ? gen[k] : ref[k];
        return out;
    }

    property var _from: ({})
    property var _to: ({})
    property bool _ready: false

    roles: {
        const t = progress.value, from = _from, to = _to;
        if (t >= 1)
            return to;
        const out = {};
        for (const k of Object.keys(to)) {
            const a = Qt.color(from[k] ?? to[k]), b = Qt.color(to[k]);
            out[k] = Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
        }
        return out;
    }

    on_TargetChanged: {
        if (!_ready)
            return;
        _from = roles;          // whatever is on screen now, even mid-crossfade
        _to = _target;
        progress.snap(0);
        progress.target = 1;
    }

    Component.onCompleted: {
        _to = _target;
        _from = _target;
        progress.snap(1);
        _ready = true;
    }

    property Spring _progress: Spring {
        id: progress
        spec: Motion.effectsSlow
    }

    property SystemClock _clock: SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: Config.options.look.theme === "auto"
    }
}
