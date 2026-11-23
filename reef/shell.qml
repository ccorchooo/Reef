import QtQuick
import Quickshell
import qs.modules
import qs.services
import qs.dev

ShellRoot {
    // Per-monitor surfaces (bar, Island, screen corners… from M1 on).
    Variants {
        model: Quickshell.screens
        ScreenScope {}
    }

    Commands {}

    LazyLoader {
        active: Config.options.debug.devWindow
        DevWindow {}
    }
}
