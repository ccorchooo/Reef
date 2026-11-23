pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// The system battery (UPower display device). `present` is false on desktops.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device.isLaptopBattery
    // 0..1 (Quickshell may report 0..100 on some versions)
    readonly property real level: device.percentage > 1 ? device.percentage / 100 : device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged

    readonly property string icon: {
        if (!present)
            return "battery_unknown";
        if (full)
            return "battery_full";
        if (charging) {
            const steps = [20, 30, 50, 60, 80, 90];
            const pct = level * 100;
            const s = steps.find(x => pct <= x);
            return s ? `battery_charging_${s}` : "battery_charging_full";
        }
        if (level < 0.05)
            return "battery_alert";
        const bars = Math.min(6, Math.floor(level * 7));
        return level >= 0.95 ? "battery_full" : `battery_${bars}_bar`;
    }

    readonly property string label: present ? `Battery ${Math.round(level * 100)}%${charging ? ", charging" : ""}` : "No battery"
}
