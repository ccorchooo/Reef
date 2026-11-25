import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components

// The wallpaper, when Reef draws it (Settings → Look → "Draw the wallpaper"; off by
// default so another wallpaper program can). A background-layer surface under everything,
// filling the whole screen; a new picture crossfades in with effects-slow.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Colors.surface
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "reef-wallpaper"
    mask: Region {}

    readonly property string path: Config.options.look.wallpaper

    // Two images: the new one fades in over the old.
    property bool showA: true
    onPathChanged: {
        if (showA)
            b.source = path ? "file://" + path : "";
        else
            a.source = path ? "file://" + path : "";
        showA = !showA;
    }

    component Picture: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    Picture {
        id: a
        source: root.path ? "file://" + root.path : ""
        opacity: fadeA.value
        Spring {
            id: fadeA
            spec: Motion.effectsSlow
            target: root.showA && a.status === Image.Ready ? 1 : 0
        }
    }
    Picture {
        id: b
        opacity: fadeB.value
        Spring {
            id: fadeB
            spec: Motion.effectsSlow
            target: !root.showA && b.status === Image.Ready ? 1 : 0
        }
    }
}
