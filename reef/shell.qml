import QtQuick
import Quickshell
import qs.modules
import qs.modules.lock
import qs.modules.polkit
import qs.services
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

    LazyLoader {
        active: Config.options.debug.devWindow
        DevWindow {}
    }
}
