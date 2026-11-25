import QtQuick
import Quickshell
import qs.modules
import qs.modules.lock
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

    // Session (M5): the lock covers every monitor; the polkit dialog opens on the focused one.
    LockScreen {}
    Variants {
        model: Quickshell.screens
        AuthDialog {}
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
