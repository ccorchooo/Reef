import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules

// Status cay (SURFACES.md → Bar): notifications bell, clock, network, volume, battery.
// Clicking it opens the control center; the clock opens the calendar, the network icon
// the Wi-Fi menu, the volume icon the audio output menu. Scrolling changes the volume.
// The bell fills when there are notifications and shows Do not disturb.
Cay {
    id: root

    required property string screenName

    leftPadding: Tokens.cayPadding
    rightPadding: Tokens.cayPadding
    color: bg.value

    readonly property bool panelOpen: PanelState.screenName === screenName && (PanelState.panel === "controlCenter")

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: root.panelOpen ? Colors.surfaceContainerHighest
            : cayMouse.containsMouse && !items.anyHovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
    }

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: `Control center. ${Notifications.count} notifications${Notifications.dnd ? ", do not disturb" : ""}. ${Battery.present ? Battery.label : ""}`
    Keys.onReturnPressed: PanelState.toggle("controlCenter", screenName)
    Keys.onSpacePressed: PanelState.toggle("controlCenter", screenName)

    MouseArea {
        id: cayMouse
        parent: root
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: PanelState.toggle("controlCenter", root.screenName)
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) >= 1)
                Audio.setVolume(Audio.volume + (d > 0 ? 0.05 : -0.05));
        }
    }

    Row {
        id: items
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.cayGapStatus
        readonly property bool anyHovered: clock.hovered || net.hovered || vol.hovered

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Notifications.dnd ? "notifications_off" : Notifications.count > 0 ? "notifications_unread" : "notifications"
            filled: Notifications.count > 0
            size: Tokens.iconSm
            color: Notifications.count > 0 && !Notifications.dnd ? Colors.on.surface : Colors.on.surfaceVariant
        }

        StatusItem {
            id: clock
            screenName: root.screenName
            menu: "calendar"
            label: `${Time.time}. Calendar`
            StyledText {
                style: "barTitle"
                text: Time.time
            }
        }

        StatusItem {
            id: net
            screenName: root.screenName
            menu: "wifi"
            label: Network.label
            Icon {
                name: Network.icon
                size: Tokens.iconSm
                color: net.hovered || net.active ? Colors.on.surface : Colors.on.surfaceVariant
            }
        }

        StatusItem {
            id: vol
            screenName: root.screenName
            menu: "audio"
            label: Audio.label
            Icon {
                name: Audio.icon
                size: Tokens.iconSm
                color: vol.hovered || vol.active ? Colors.on.surface : Colors.on.surfaceVariant
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            name: Battery.icon
            size: Tokens.iconSm
            color: Battery.low ? Colors.error : Colors.on.surfaceVariant
        }
    }
}
