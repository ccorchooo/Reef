import QtQuick
import qs.theme
import qs.services
import qs.components

// Status cay (SURFACES.md → Bar): notifications bell, clock, network, volume, battery.
// Clicking it opens the control center; clicking the clock opens the calendar (both M3).
Cay {
    id: root

    leftPadding: Tokens.cayPadding
    rightPadding: Tokens.cayPadding
    color: bg.value

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: cayMouse.containsMouse && !clockMouse.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
    }

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: `Status and control center. ${Time.time}. ${Network.label}. ${Audio.label}` + (Battery.present ? `. ${Battery.label}` : "")
    Keys.onReturnPressed: Actions.run("controlCenter")
    Keys.onSpacePressed: Actions.run("controlCenter")

    MouseArea {
        id: cayMouse
        parent: root
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Actions.run("controlCenter")
        // Scroll over the cay to change the volume.
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) >= 1)
                Audio.setVolume(Audio.volume + (d > 0 ? 0.05 : -0.05));
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.cayGapStatus

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "notifications"
            size: Tokens.iconSm
        }

        StyledText {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            style: "barTitle"
            text: Time.time

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                anchors.margins: -Tokens.space1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Actions.run("calendar")
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Network.icon
            size: Tokens.iconSm
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Audio.icon
            size: Tokens.iconSm
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            name: Battery.icon
            size: Tokens.iconSm
            color: Battery.level < 0.1 && !Battery.charging ? Colors.error : Colors.on.surfaceVariant
        }
    }
}
