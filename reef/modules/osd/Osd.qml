import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// Volume / brightness OSD (SURFACES.md → Notifications, OSD and toasts;
// screens/Notifications). A floating card near the right edge, vertically centered,
// with radius-xl on every corner and shadow-menu; a level and an icon, no number.
// It slides in from the right on the focused monitor only. Drag or scroll on it to
// adjust.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-osd"

    // Room for the shadow, the card, and its space-4 margin from the edge (the shadow on
    // that side runs off the screen anyway). Hidden, it slides fully past the edge.
    readonly property real shadowRoom: Colors.shadowMenu.blur + Math.abs(Colors.shadowMenu.y)
    readonly property real travel: Tokens.osdWidth + Tokens.space4 + shadowRoom
    implicitWidth: shadowRoom + Tokens.osdWidth + Tokens.space4
    implicitHeight: Tokens.osdHeight + shadowRoom * 2

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
        target: root.shown ? 0 : root.travel
    }

    visible: shown || slide.value < root.travel - 0.5

    Item {
        id: panel
        x: root.shadowRoom + slide.value
        y: (root.height - height) / 2
        width: Tokens.osdWidth
        height: Tokens.osdHeight

        RectangularShadow {
            anchors.fill: body
            radius: body.radius
            offset.x: Colors.shadowMenu.x
            offset.y: Colors.shadowMenu.y
            blur: Colors.shadowMenu.blur
            color: Colors.shadowMenu.color
        }

        Rectangle {
            id: body
            anchors.fill: parent
            color: Colors.surfaceContainer
            radius: Tokens.radiusXl

            Accessible.role: Accessible.Indicator
            Accessible.name: root.kind === "volume" ? Audio.label : `Brightness ${Math.round(Brightness.level * 100)}%`

            HoverHandler { id: panelHover }

            Column {
                anchors.fill: parent
                anchors.margins: (Tokens.osdWidth - Tokens.osdTrack) / 2
                spacing: Tokens.space2_5

                Rectangle {
                    id: track
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Tokens.osdTrack
                    height: parent.height - iconItem.height - parent.spacing
                    radius: width / 2
                    color: Colors.surfaceContainerHighest

                    // The fill is clipped to the track's rounded shape (a plain `clip`
                    // is rectangular, so the fill's corners poked out at the ends).
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: trackShape
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: Math.max(0, Math.min(1, fill.value)) * parent.height
                            color: Colors.primary
                            topLeftRadius: Tokens.radiusFillCap
                            topRightRadius: Tokens.radiusFillCap
                            Spring {
                                id: fill
                                spec: Motion.spatialFast
                                target: root.level
                            }
                        }
                    }
                    Rectangle {
                        id: trackShape
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        layer.enabled: true
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
    }
}
