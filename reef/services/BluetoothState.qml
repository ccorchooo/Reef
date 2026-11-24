pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// The Bluetooth adapter and devices, for the quick toggle and the Bluetooth menu.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.paired || d.connected || d.name)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || String(a.name).localeCompare(String(b.name)))
    readonly property var connected: devices.filter(d => d.connected)

    readonly property string label: !available ? "Unavailable"
        : !enabled ? "Off"
        : connected.length === 1 ? connected[0].name
        : connected.length > 1 ? `${connected.length} devices` : "On"

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function toggle() {
        setEnabled(!enabled);
    }

    // Look for new devices while the menu is open.
    function scan(on) {
        if (adapter && enabled)
            adapter.discovering = on;
    }

    function activate(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    function icon(device) {
        const i = device?.icon ?? "";
        if (i.includes("headset"))
            return "headset_mic";
        if (i.includes("headphone") || i.includes("audio-card"))
            return "headphones";
        if (i.includes("speaker"))
            return "speaker";
        if (i.includes("gaming"))
            return "sports_esports";
        if (i.includes("mouse"))
            return "mouse";
        if (i.includes("keyboard"))
            return "keyboard";
        if (i.includes("phone"))
            return "smartphone";
        return "bluetooth";
    }
}
