pragma Singleton
import QtQuick
import Quickshell
import qs.services

// The order of the bar's cays (Config bar.cays): the ones before "|" pack from the start of
// the bar, the rest from the far end. Unknown ids are dropped, and any missing cay is put
// back (Status at the end, the others at the start), so the saved order is always whole.
// Edit mode and Settings rearrange it.
Singleton {
    id: root

    readonly property var all: ["dock", "navigator", "workspaces", "spotlight", "status"]
    readonly property var labels: ({
            dock: "Dock",
            navigator: "Navigator",
            workspaces: "Workspaces",
            spotlight: "Spotlight",
            status: "Status",
            "|": "Gap"
        })
    readonly property var icons: ({
            dock: "apps",
            navigator: "explore",
            workspaces: "filter_1",
            spotlight: "music_note",
            status: "schedule",
            "|": "space_bar"
        })

    readonly property var order: {
        const saved = Array.from(Config.options.bar.cays).filter(id => all.includes(id) || id === "|");
        let list = saved.filter((id, i) => saved.indexOf(id) === i);
        if (!list.includes("|"))
            list.push("|");
        for (const id of all) {
            if (list.includes(id))
                continue;
            if (id === "status")
                list.push(id);
            else
                list.splice(list.indexOf("|"), 0, id);
        }
        return list;
    }

    // The order as shown in edit mode and Settings: without the Workspaces cay when it's off.
    readonly property var shown: order.filter(id => id !== "workspaces" || Config.options.bar.workspacesCay)

    // Saves a reordered `shown` list, keeping a hidden Workspaces cay where it was.
    function setShown(list) {
        if (!list.includes("workspaces")) {
            const i = order.indexOf("workspaces");
            const before = order.slice(0, i).reverse().find(id => list.includes(id));
            list = list.slice();
            list.splice(before === undefined ? 0 : list.indexOf(before) + 1, 0, "workspaces");
        }
        Config.options.bar.cays = list;
    }
}
