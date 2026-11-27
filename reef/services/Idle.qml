pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// What happens when you step away (Settings → Power & performance → When idle):
// lock after idle.lockMinutes, turn the screens off after idle.screenOffMinutes, and
// sleep after idle.suspendMinutes (on battery: idle.suspendOnBatteryMinutes). 0 = never.
// Every timer respects idle inhibitors: Keep awake (an IdleInhibitor in the bar), a
// fullscreen video or game (Hyprland's idle_inhibit rule), and apps that ask.
// Playing media holds the lock and sleep timers too, unless idle.whileMedia is on.
// Started by modules/Commands (singletons start on first use).
Singleton {
    id: root

    readonly property var options: Config.options.idle
    readonly property bool enabled: options.enabled && !Lock.preview
    readonly property bool mediaHolds: !options.whileMedia && Media.playing
    readonly property int suspendMinutes: Battery.unplugged ? options.suspendOnBatteryMinutes : options.suspendMinutes

    function _dpms(on) {
        const lua = `hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })`;
        Quickshell.execDetached(Hyprland.usingLua ? ["hyprctl", "dispatch", lua] : ["hyprctl", "dispatch", "dpms", on ? "on" : "off"]);
    }

    IdleMonitor {
        enabled: root.enabled && root.options.lockMinutes > 0 && !root.mediaHolds
        timeout: Math.max(1, root.options.lockMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && !Lock.locked) Lock.lock()
    }

    IdleMonitor {
        enabled: root.enabled && root.options.screenOffMinutes > 0
        timeout: Math.max(1, root.options.screenOffMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: root._dpms(!isIdle)
    }

    IdleMonitor {
        enabled: root.enabled && root.suspendMinutes > 0 && !root.mediaHolds
        timeout: Math.max(1, root.suspendMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Session.suspend()
    }
}
