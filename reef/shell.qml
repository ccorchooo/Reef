import QtQuick
import Quickshell
import qs.modules
import qs.modules.lock
import qs.modules.coral
import qs.modules.polkit
import qs.services
import qs.settings
import qs.dev

ShellRoot {
    // Per-monitor surfaces (bar, Island, screen corners… from M1 on).
    Variants {
        model: Quickshell.screens
        ScreenScope {}
    }

    Commands {}

    // Hyprland's borders follow Reef's colors (a singleton starts on first use).
    readonly property bool _compositorTheme: CompositorTheme.enabled

    // Session (M5): the lock covers every monitor; the polkit dialog opens on the focused one.
    LockScreen {}
    Variants {
        model: Quickshell.screens
        AuthDialog {}
    }

    // The Coral app (M8): its own window, built only while open.
    LazyLoader {
        active: Coral.appOpen
        CoralApp {}
    }

    // The Settings app (M7): its own window, built only while open.
    LazyLoader {
        active: SettingsState.open
        Settings {}
    }
    Connections {
        target: Actions
        function onSettingsRequested(page) { SettingsState.show(page); }
    }

    LazyLoader {
        active: Config.options.debug.devWindow
        DevWindow {}
    }
}
