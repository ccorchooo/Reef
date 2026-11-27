import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.modules.greeter

// Reef's login greeter: a second entry point beside shell.qml, run by greetd inside a
// small Hyprland (greeter/hyprland.lua):  qs -p /usr/share/reef/reef/greeter.qml
// The form shows on the focused monitor; the others show the wallpaper and the clock.
ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool main: (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name) === (modelData?.name ?? "")

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "reef-greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            GreeterSurface {
                anchors.fill: parent
                form: win.main
                focus: win.main
            }
        }
    }
}
