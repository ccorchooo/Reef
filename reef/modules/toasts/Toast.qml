import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// Toasts (SURFACES.md → Notifications, OSD and toasts; screens/Notifications):
// centered above the bar on inverse-surface, on the focused monitor. They rise
// from the bar with spatial-default and fade with effects-default.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-toast"

    // Above the bar when this monitor has one along the bottom.
    readonly property var monitorSettings: Config.monitor(modelData.name)
    readonly property real barSpace: monitorSettings.showBar && monitorSettings.barPosition !== "left" ? Tokens.cayHeight + Tokens.space2 * 2 : 0
    readonly property real shadowRoom: Colors.shadowToast.blur + Colors.shadowToast.y
    implicitWidth: Math.max(1, pill.implicitWidth + shadowRoom * 2)
    implicitHeight: barSpace + Tokens.space4 + Tokens.toastHeight + shadowRoom

    mask: Region { item: pill }

    property var toast: null
    readonly property bool shown: !!Toasts.current && (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name
    onShownChanged: if (shown) toast = Toasts.current
    Connections {
        target: Toasts
        function onCurrentChanged() { if (root.shown) root.toast = Toasts.current; }
    }

    Spring {
        id: rise
        spec: Motion.spatialDefault
        target: root.shown ? 0 : Tokens.toastHeight + Tokens.space4
    }
    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.shown ? 1 : 0
    }
    visible: shown || fade.value > 0.01

    RectangularShadow {
        anchors.fill: pill
        radius: pill.radius
        offset.x: Colors.shadowToast.x
        offset.y: Colors.shadowToast.y
        blur: Colors.shadowToast.blur
        color: Colors.shadowToast.color
        opacity: pill.opacity
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - root.barSpace - Tokens.space4 - height + rise.value
        // 8px after an action button (it has its own padding), otherwise even with the start.
        implicitWidth: row.implicitWidth + Tokens.toastPaddingStart + (root.toast?.action ? Tokens.space2 : Tokens.toastPaddingStart)
        height: Tokens.toastHeight
        width: implicitWidth
        radius: height / 2
        color: Colors.inverseSurface
        opacity: fade.value

        Accessible.role: Accessible.AlertMessage
        Accessible.name: root.toast?.text ?? ""

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.toastPaddingStart
            spacing: Tokens.space3

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!root.toast?.icon
                name: root.toast?.icon ?? ""
                size: Tokens.iconSm
                color: Colors.inverseOnSurface
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                style: "toastLabel"
                color: Colors.inverseOnSurface
                text: root.toast?.text ?? ""
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!root.toast?.action
                width: actionLabel.implicitWidth + Tokens.space3 * 2
                height: Tokens.toastActionHeight

                activeFocusOnTab: visible
                Accessible.role: Accessible.Button
                Accessible.name: root.toast?.action ?? ""

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colors.inversePrimary
                    opacity: actionMouse.pressed ? Tokens.statePressedOpacity : actionMouse.containsMouse ? Tokens.stateHoverOpacity : 0
                }
                StyledText {
                    id: actionLabel
                    anchors.centerIn: parent
                    style: "toastAction"
                    color: Colors.inversePrimary
                    text: root.toast?.action ?? ""
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Toasts.act()
                }
            }
        }
    }
}
