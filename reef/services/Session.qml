pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Power and session actions (SURFACES.md → Power actions, Lock screen).
Singleton {
    id: root

    function lock() {
        Lock.lock();
    }

    // Leaves Hyprland (hyprshutdown first, when it's installed, so apps close cleanly).
    function logout() {
        const exit = Hyprland.usingLua ? "hyprctl dispatch 'hl.dsp.exit()'" : "hyprctl dispatch exit";
        Quickshell.execDetached(["sh", "-c", `command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || ${exit}`]);
    }

    function suspend() {
        if (Config.options.session.lockBeforeSleep)
            Lock.lock();
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
