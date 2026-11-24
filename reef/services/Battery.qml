pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.theme

// The system battery (UPower display device). `present` is false on desktops.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device.isLaptopBattery
    // 0..1 (Quickshell may report 0..100 on some versions)
    readonly property real level: device.percentage > 1 ? device.percentage / 100 : device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property string percent: `${Math.round(level * 100)}%`

    // Settings → Power & performance → Low battery
    readonly property bool low: present && !charging && !full && level <= Config.options.battery.lowLevel
    readonly property bool critical: low && level <= Config.options.battery.criticalLevel

    // True for a moment after the charger is plugged in (activity-notice).
    property bool chargingNotice: false

    readonly property bool powerSaverAvailable: PowerProfiles.profile !== undefined
    readonly property bool powerSaver: PowerProfiles.profile === PowerProfile.PowerSaver
    function usePowerSaver() {
        PowerProfiles.profile = PowerProfile.PowerSaver;
    }

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

    readonly property string label: present ? `Battery ${percent}${charging ? ", charging" : ""}` : "No battery"

    onChargingChanged: {
        if (charging && _armed) {
            chargingNotice = true;
            noticeTimer.restart();
        } else if (!charging) {
            chargingNotice = false;
        }
    }

    // UPower reports its state right after start; that isn't "plugged in".
    property bool _armed: false
    Timer {
        running: true
        interval: Tokens.activityNotice
        onTriggered: root._armed = true
    }

    Timer {
        id: noticeTimer
        interval: Tokens.activityNotice
        onTriggered: root.chargingNotice = false
    }
}
