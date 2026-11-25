pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.modules

// The control center's quick toggles, shared by the control center and edit mode's tile
// layout. Their order is Config controlCenter.tiles (edit mode rearranges it); rows are
// packed four columns wide, with Wi-Fi, Bluetooth, Keep awake and Focus taking two.
Singleton {
    id: root

    readonly property var all: ["wifi", "bluetooth", "dnd", "nightLight", "screenshot", "micMute", "keepAwake", "focus"]
    readonly property var wideTiles: ["wifi", "bluetooth", "keepAwake", "focus"]
    readonly property int columns: 4

    // The saved order, without unknown ids and with any new tiles at the end.
    readonly property var order: {
        const saved = Array.from(Config.options.controlCenter.tiles).filter(t => all.includes(t));
        const unique = saved.filter((t, i) => saved.indexOf(t) === i);
        return unique.concat(all.filter(t => !unique.includes(t)));
    }
    readonly property var rows: pack(order)

    function wide(id) { return wideTiles.includes(id); }
    function span(id) { return wide(id) ? 2 : 1; }

    // [[id, …], …]: a tile that doesn't fit in what's left of a row starts the next one.
    function pack(list) {
        const out = [];
        let row = [], used = 0;
        for (const id of list) {
            if (used + span(id) > columns) {
                out.push(row);
                row = [];
                used = 0;
            }
            row.push(id);
            used += span(id);
        }
        if (row.length)
            out.push(row);
        return out;
    }

    // Where each tile sits: { id: { row, col, span } }.
    function slots(list) {
        const out = {};
        pack(list).forEach((row, r) => {
            let c = 0;
            for (const id of row) {
                out[id] = { row: r, col: c, span: span(id) };
                c += span(id);
            }
        });
        return out;
    }

    function setOrder(list) {
        Config.options.controlCenter.tiles = list;
    }

    function icon(id) {
        switch (id) {
        case "wifi": return Network.wired ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off";
        case "bluetooth": return "bluetooth";
        case "dnd": return "do_not_disturb_on";
        case "nightLight": return "nightlight";
        case "screenshot": return "screenshot_region";
        case "micMute": return "mic_off";
        case "keepAwake": return "coffee";
        case "focus": return "self_improvement";
        }
        return "";
    }

    function label(id) {
        switch (id) {
        case "wifi": return Network.wired ? "Ethernet" : "Wi-Fi";
        case "bluetooth": return "Bluetooth";
        case "dnd": return "Do not disturb";
        case "nightLight": return "Night light";
        case "screenshot": return "Screenshot";
        case "micMute": return "Mute microphone";
        case "keepAwake": return "Keep awake";
        case "focus": return "Focus";
        }
        return "";
    }

    function sublabel(id) {
        switch (id) {
        case "wifi": return Network.shortLabel;
        case "bluetooth": return BluetoothState.label;
        case "keepAwake": return KeepAwake.active ? (KeepAwake.until > 0 ? `${KeepAwake.text} left` : "On") : "Off";
        case "focus": return Focus.active ? `${Focus.phase === "focus" ? "Focus" : "Break"} · ${Focus.text}` : `${Config.options.focus.focusMinutes} min`;
        }
        return "";
    }

    function checked(id) {
        switch (id) {
        case "wifi": return Network.wired ? true : Network.wifiEnabled;
        case "bluetooth": return BluetoothState.enabled;
        case "dnd": return Notifications.dnd;
        case "nightLight": return NightLight.enabled;
        case "micMute": return Audio.micMuted;
        case "keepAwake": return KeepAwake.active;
        case "focus": return Focus.active;
        }
        return false;
    }

    function available(id) {
        return id === "bluetooth" ? BluetoothState.available : true;
    }

    function hasMenu(id) {
        return id === "wifi" || id === "bluetooth";
    }

    function toggle(id) {
        switch (id) {
        case "wifi":
            Network.wired ? PanelState.open("wifi") : Network.setWifiEnabled(!Network.wifiEnabled);
            break;
        case "bluetooth": BluetoothState.toggle(); break;
        case "dnd": Notifications.setDnd(!Notifications.dnd); break;
        case "nightLight": NightLight.toggle(); break;
        case "screenshot":
            PanelState.closeAll();
            Screenshot.region();
            break;
        case "micMute": Audio.toggleMicMute(); break;
        case "keepAwake": KeepAwake.toggle(0); break;
        case "focus": Focus.active ? Focus.stop() : Focus.start(0); break;
        }
    }

    function openMenu(id) {
        if (hasMenu(id))
            PanelState.open(id);
    }
}
