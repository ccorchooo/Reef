import QtQuick
import Quickshell
import qs.services
import qs.modules.frame
import qs.modules.bar
import qs.modules.island
import qs.modules.osd
import qs.modules.toasts
import qs.modules.controlcenter
import qs.modules.menus

// One per monitor. Each surface can be turned off per monitor (Settings → Displays).
Scope {
    id: root

    required property ShellScreen modelData
    readonly property var settings: Config.monitor(modelData.name)

    LazyLoader {
        active: root.settings.showCorners
        ScreenCorners { modelData: root.modelData }
    }

    LazyLoader {
        active: root.settings.showBar
        Bar { modelData: root.modelData }
    }

    LazyLoader {
        active: root.settings.showIsland
        Island { modelData: root.modelData }
    }

    // Panels and menus open on one monitor at a time (PanelState).
    ControlCenter { modelData: root.modelData }
    QuickMenu { modelData: root.modelData }

    // OSD and toasts appear on whichever monitor has focus.
    Osd { modelData: root.modelData }
    Toast { modelData: root.modelData }
}
