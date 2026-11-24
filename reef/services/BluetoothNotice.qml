pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.theme

// A short notice when a Bluetooth device connects (headphones, speakers, controllers…),
// with its battery when it reports one. Devices already connected when Reef starts
// don't trigger it.
Singleton {
    id: root

    property bool showing: false
    property var device: null
    readonly property string name: device?.name || device?.deviceName || "Bluetooth device"
    readonly property bool hasBattery: device?.batteryAvailable ?? false
    // 0..1 (BlueZ reports a percentage; Quickshell may pass either form)
    readonly property real battery: {
        const b = device?.battery ?? 0;
        return b > 1 ? b / 100 : b;
    }
    readonly property string icon: {
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

    function show(d) {
        device = d;
        showing = true;
        hold.restart();
    }

    property bool _armed: false
    Timer {
        running: true
        interval: Tokens.activityNotice
        onTriggered: root._armed = true
    }

    Timer {
        id: hold
        interval: Tokens.activityNotice
        onTriggered: root.showing = false
    }

    Variants {
        model: Bluetooth.devices.values
        Connections {
            required property var modelData
            target: modelData
            function onConnectedChanged() {
                if (root._armed && modelData.connected)
                    root.show(modelData);
            }
        }
    }
}
