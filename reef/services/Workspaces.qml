pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme

// Hyprland workspaces and windows for the Navigator cay, the workspace overview and
// the Alt+Tab switcher.
// Hyprland 0.57 can be configured in Lua, which changes the dispatch syntax;
// Quickshell reports which one is active through Hyprland.usingLua.
Singleton {
    id: root

    readonly property var all: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1

    // Id of the workspace shown on a monitor (by output name).
    function activeOn(monitorName) {
        const m = Hyprland.monitors.values.find(m => m.name === monitorName);
        return m?.activeWorkspace?.id ?? focusedId;
    }

    function occupied(id) {
        const w = all.find(w => w.id === id);
        return !!w && w.toplevels.values.length > 0;
    }

    function windowCount(id) {
        const w = all.find(w => w.id === id);
        return w ? w.toplevels.values.length : 0;
    }

    // Ids to show: 1..count, plus any higher workspace that exists.
    function ids(count) {
        const out = [];
        for (let i = 1; i <= count; i++)
            out.push(i);
        for (const w of all)
            if (w.id > count && !out.includes(w.id))
                out.push(w.id);
        return out.sort((a, b) => a - b);
    }

    function goTo(id) {
        dispatchFocus(String(id));
    }

    // How long Hyprland's workspace slide takes (animations → workspaces; speed is in
    // 100 ms steps), so the overview can stay over the screen until it ends.
    property real switchDuration: Tokens.workspaceSwitchFallback
    property Process _animations: Process {
        running: true
        command: ["hyprctl", "animations", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(text).flat();
                    const ws = all.find(a => a.name === "workspaces");
                    if (ws)
                        root.switchDuration = ws.enabled ? ws.speed * 100 : 0;
                } catch (e) {}
            }
        }
    }

    // ── home ────────────────────────────────────────────────────
    // The home screen is an empty workspace (the desktop and its widgets). openHome() goes
    // to the first empty one (the Navigator's home button). Edit mode uses goHome(), which
    // remembers where it came from, and leaveHome() to go back unless something was opened
    // there in the meantime.
    property var _homeFrom: ({})      // monitor → workspace id to return to
    function openHome(monitorName) {
        if (windowCount(activeOn(monitorName)) > 0)
            dispatchFocus("empty");
    }
    function goHome(monitorName) {
        const current = activeOn(monitorName);
        if (windowCount(current) === 0)
            return;
        const map = Object.assign({}, _homeFrom);
        map[monitorName] = current;
        _homeFrom = map;
        dispatchFocus("empty");
    }
    function leaveHome(monitorName) {
        const from = _homeFrom[monitorName];
        if (from === undefined)
            return;
        const map = Object.assign({}, _homeFrom);
        delete map[monitorName];
        _homeFrom = map;
        const now = activeOn(monitorName);
        if (windowCount(now) === 0 && now !== from)
            afterHandoff(() => goTo(from));
    }

    // "+1" / "-1" for relative moves (scrolling over the Navigator).
    function step(delta) {
        dispatchFocus(delta > 0 ? "+1" : "-1");
    }

    function dispatchFocus(target) {
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${target}" })`);
        else
            Hyprland.dispatch(`workspace ${target.startsWith("+") || target.startsWith("-") ? "e" + target : target}`);
    }

    // ── windows ─────────────────────────────────────────────────
    // Positions, sizes and focus order come from Hyprland's IPC objects, which only fill
    // in after a refresh: call refresh() when a surface that needs them opens.
    function refresh() {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    // Windows on a workspace (HyprlandToplevels).
    function windowsOn(id) {
        const w = all.find(w => w.id === id);
        return w ? w.toplevels.values : [];
    }

    // Windows on normal workspaces, most recently focused first.
    readonly property var recentWindows: Hyprland.toplevels.values
        .filter(t => (t.workspace?.id ?? 0) > 0)
        .sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 1e6) - (b.lastIpcObject?.focusHistoryID ?? 1e6))

    // Focus a window, switching to its workspace.
    function focusWindow(t) {
        const address = t?.address ?? "";
        if (address !== "" && Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${address.replace(/^0x/, "")}" })`);
        else if (address !== "")
            Hyprland.dispatch(`focuswindow address:0x${address.replace(/^0x/, "")}`);
        else
            t?.wayland?.activate();
    }

    // Run `f` once a surface that held the keyboard (overview, switcher) has let it go.
    // Done at once, Hyprland's refocus of the previous window would undo the switch.
    function afterHandoff(f) {
        _pending = f;
        handoff.restart();
    }
    property var _pending: null
    property Timer _handoff: Timer {
        id: handoff
        interval: Tokens.focusHandoffDelay
        onTriggered: {
            const f = root._pending;
            root._pending = null;
            f?.();
        }
    }
}
