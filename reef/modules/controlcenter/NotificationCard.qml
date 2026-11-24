import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// One notification in the control center (screens/ControlCenter): app icon tile,
// app · time, summary, body, and its actions as chips. Notification cards are plain
// rounded rectangles so reading stays calm. Middle-click or the close button dismisses.
Rectangle {
    id: root

    required property var notification
    property real now: Date.now()

    readonly property string appIcon: notification?.appIcon ? Quickshell.iconPath(notification.appIcon, true) : ""
    readonly property string image: notification?.image ?? ""

    implicitHeight: row.implicitHeight + Tokens.space3 * 2
    radius: Tokens.radiusLg
    color: hover.hovered ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

    activeFocusOnTab: true
    Accessible.role: Accessible.ListItem
    Accessible.name: `${notification?.appName}: ${notification?.summary}. ${notification?.body}`
    Keys.onDeletePressed: Notifications.dismiss(notification)

    HoverHandler { id: hover }

    Row {
        id: row
        x: Tokens.space3_5
        y: Tokens.space3
        width: parent.width - Tokens.space3_5 * 2
        spacing: Tokens.space3

        ClippingRectangle {
            width: Tokens.notificationIcon
            height: Tokens.notificationIcon
            radius: Tokens.radiusMd
            color: Colors.secondary

            Icon {
                anchors.centerIn: parent
                visible: !appIconImage.visible && !imageItem.visible
                name: "notifications"
                filled: true
                size: Tokens.iconMd
                color: Colors.on.secondary
            }
            IconImage {
                id: appIconImage
                anchors.centerIn: parent
                implicitSize: Tokens.iconLg
                visible: root.appIcon !== "" && !imageItem.visible && status === Image.Ready
                source: root.appIcon
            }
            Image {
                id: imageItem
                anchors.fill: parent
                visible: root.image !== "" && status === Image.Ready
                source: root.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: parent.width - Tokens.notificationIcon - close.width - parent.spacing * 2
            spacing: Tokens.spaceHalf

            Row {
                spacing: Tokens.cayPaddingTight
                StyledText {
                    style: "notificationApp"
                    color: Colors.on.surfaceVariant
                    text: root.notification?.appName || "App"
                }
                StyledText {
                    style: "bodySm"
                    color: Colors.on.surfaceVariant
                    text: "· " + Notifications.ago(root.notification, root.now)
                }
            }
            StyledText {
                width: parent.width
                style: "notificationTitle"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.notification?.summary ?? ""
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: "notificationBody"
                color: Colors.on.surfaceVariant
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.notification?.body ?? ""
            }
            Item {
                width: 1
                height: Tokens.cayPaddingTight
                visible: actionsRow.visible
            }
            Flow {
                id: actionsRow
                width: parent.width
                spacing: Tokens.space2
                visible: (root.notification?.actions?.length ?? 0) > 0
                Repeater {
                    model: root.notification?.actions ?? []
                    Chip {
                        required property var modelData
                        required property int index
                        text: modelData.text || "Open"
                        tone: index === 0 ? "accent" : "neutral"
                        neutralColor: Colors.surfaceContainerHighest
                        onClicked: Notifications.invoke(root.notification, modelData)
                    }
                }
            }
        }

        CayButton {
            id: close
            size: Tokens.chipHeight
            icon: "close"
            iconSize: Tokens.iconSm
            label: "Dismiss"
            opacity: hover.hovered || activeFocus ? 1 : 0
            onClicked: Notifications.dismiss(root.notification)
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.MiddleButton | Qt.LeftButton
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                Notifications.dismiss(root.notification);
            else {
                // The default action, if the app gave one.
                const def = root.notification?.actions?.find(a => a.identifier === "default");
                if (def)
                    Notifications.invoke(root.notification, def);
            }
        }
    }
}
