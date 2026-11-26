import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

// The session lock (SURFACES.md → Lock screen). While Lock.locked, WlSessionLock covers
// every monitor with a LockSurface. The preview (`ipc call lock preview`) shows one on
// the focused monitor in an overlay instead, without locking anything.
Scope {
    id: root

    WlSessionLock {
        locked: Lock.locked
        // Lets a waiting sleep go once every monitor is covered (Lock → lid and sleep).
        onSecureChanged: Lock.secure = secure

        WlSessionLockSurface {
            id: lockSurface
            color: Colors.surface
            LockSurface {
                anchors.fill: parent
                focus: true
                screenName: lockSurface.screen?.name ?? ""
            }
        }
    }

    LazyLoader {
        active: Lock.preview

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Lock.previewScreen) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "reef-lock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LockSurface {
                anchors.fill: parent
                focus: true
                screenName: Lock.previewScreen
            }
        }
    }
}
