import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// Volume / brightness OSD (SURFACES.md → Notifications, OSD and toasts;
// screens/Notifications). Attached to the right edge, vertically centered,
// joined to the edge with concave fillets; a level and an icon, no number.
// It slides in from the edge it lives on, on the focused monitor only.
// Drag or scroll on it to adjust.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-osd"
    implicitWidth: Tokens.osdWidth
    implicitHeight: Tokens.osdHeight + Tokens.radiusXl * 2

    mask: Region { item: panel }

    property string kind: "volume"   // "volume" | "brightness"
    property bool shown: false
    readonly property real level: kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.level
    readonly property string icon: kind === "volume" ? Audio.icon
        : Brightness.level < 0.34 ? "brightness_low" : Brightness.level < 0.67 ? "brightness_medium" : "brightness_high"

    function show(what) {
        if (!Config.options.osd.enabled || Hyprland.focusedMonitor?.name !== modelData.name)
            return;
        // The control center and audio menu already show the level.
        if (PanelState.panel === "controlCenter" || PanelState.menu === "audio")
            return;
        kind = what;
        shown = true;
        hideTimer.restart();
    }

    // Ignore the values Pipewire reports while connecting.
    property bool _armed: false
    Timer {
        running: true
        interval: Tokens.osdTimeout
        onTriggered: root._armed = true
    }

    Connections {
        target: Audio
        function onVolumeChanged() { if (root._armed) root.show("volume"); }
        function onMutedChanged() { if (root._armed) root.show("volume"); }
    }
    Connections {
        target: Brightness
        function onChangedByUser() { root.show("brightness"); }
    }

    Timer {
        id: hideTimer
        interval: Tokens.osdTimeout
        onTriggered: if (!panelHover.hovered && !drag.pressed) root.shown = false
    }

    Spring {
        id: slide
        spec: Motion.spatialDefault
        target: root.shown ? 0 : Tokens.osdWidth
    }

    visible: shown || slide.value < Tokens.osdWidth - 0.5

    Item {
        id: panel
        x: slide.value
        width: Tokens.osdWidth
        height: parent.height

        EdgeFillet {
            anchors.right: parent.right
            anchors.top: parent.top
            corner: "bottomRight"
            color: Colors.surfaceContainerLow
        }

        Rectangle {
            id: body
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.osdWidth
            height: Tokens.osdHeight
            color: Colors.surfaceContainerLow
            topLeftRadius: Tokens.radiusXl
            bottomLeftRadius: Tokens.radiusXl

            Accessible.role: Accessible.Indicator
            Accessible.name: root.kind === "volume" ? Audio.label : `Brightness ${Math.round(Brightness.level * 100)}%`

            HoverHandler { id: panelHover }

            Column {
                anchors.fill: parent
                anchors.topMargin: Tokens.space3
                anchors.bottomMargin: Tokens.space3
                anchors.leftMargin: Tokens.space4
                anchors.rightMargin: Tokens.space3_5
                spacing: Tokens.space2_5

                Rectangle {
                    id: track
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Tokens.osdTrack
                    height: parent.height - iconItem.height - parent.spacing
                    radius: width / 2
                    color: Colors.surfaceContainerHighest
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(0, Math.min(1, fill.value)) * parent.height
                        color: Colors.primary
                        topLeftRadius: Tokens.radiusFillCap
                        topRightRadius: Tokens.radiusFillCap
                        bottomLeftRadius: width / 2
                        bottomRightRadius: width / 2
                        Spring {
                            id: fill
                            spec: Motion.spatialFast
                            target: root.level
                        }
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function apply(y) {
                            const v = 1 - Math.max(0, Math.min(1, y / height));
                            root.kind === "volume" ? Audio.setVolume(v) : Brightness.set(v);
                        }
                        onPressed: event => apply(event.y)
                        onPositionChanged: event => { if (pressed) apply(event.y); }
                        onReleased: hideTimer.restart()
                        onWheel: event => {
                            const d = event.angleDelta.y > 0 ? 0.05 : -0.05;
                            root.kind === "volume" ? Audio.setVolume(Audio.volume + d) : Brightness.step(d);
                        }
                    }
                }

                Icon {
                    id: iconItem
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: root.icon
                    filled: true
                    size: Tokens.iconOsd
                    color: Colors.primary
                }
            }
        }

        EdgeFillet {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            corner: "topRight"
            color: Colors.surfaceContainerLow
        }
    }
}
