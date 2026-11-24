import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services

// A window's live picture (workspace overview, Alt+Tab switcher): the window captured
// with ScreencopyView, clipped to rounded corners, with an outline-variant edge. Until
// the first frame arrives (or if capture isn't possible) it shows the app's icon on
// surface-container-high.
//
//   WindowThumb { toplevel: hyprlandToplevel; width: 224; height: 140; live: true }
Item {
    id: root

    // A HyprlandToplevel.
    property var toplevel: null
    property bool live: true
    property real radius: Tokens.radiusMd
    // Fit the picture inside the item keeping the window's shape (switcher) or fill it
    // (overview, where the item already has the window's shape).
    property bool fit: false

    readonly property var entry: Apps.entryFor(toplevel?.lastIpcObject?.class ?? "")
    // The picture has arrived.
    readonly property bool ready: view.hasContent

    Rectangle {
        id: placeholder
        anchors.fill: parent
        radius: root.radius
        color: Colors.surfaceContainerHigh
        visible: !view.hasContent

        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.min(parent.width, parent.height) / 3
            source: Quickshell.iconPath(root.entry?.icon ?? root.toplevel?.lastIpcObject?.class ?? "", "application-x-executable")
        }
    }

    Item {
        id: picture
        anchors.centerIn: parent
        width: root.fit ? view.implicitWidth : root.width
        height: root.fit ? view.implicitHeight : root.height
        visible: view.hasContent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        ScreencopyView {
            id: view
            anchors.fill: parent
            captureSource: root.toplevel?.wayland ?? null
            live: root.live && root.visible && Config.options.performance.liveThumbnails
            constraintSize: Qt.size(root.width, root.height)
        }
    }

    Rectangle {
        id: shape
        anchors.fill: picture
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    // Edge
    Rectangle {
        anchors.fill: view.hasContent ? picture : placeholder
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Colors.outlineVariant
    }
}
