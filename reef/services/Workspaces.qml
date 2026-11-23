pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland workspaces for the Navigator cay.
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
}
