import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// A new notification in the Island (screens/Notifications): app icon, app · time,
// summary and body, then an inline reply field (when the app supports it) or the
// app's actions. Clicking the card runs the default action; the close button dismisses.
Item {
    id: root

    property var notification: null
    readonly property bool replying: reply.activeFocus
    readonly property var actions: (notification?.actions ?? []).filter(a => a.identifier !== "default")

    implicitHeight: column.implicitHeight
    signal wantsKeyboard

    readonly property string appIcon: notification?.appIcon ? Quickshell.iconPath(notification.appIcon, true) : ""
    readonly property string image: notification?.image ?? ""

    Column {
        id: column
        width: parent.width
        spacing: Tokens.space3

        Row {
            width: parent.width
            spacing: Tokens.space3

            ClippingRectangle {
                width: Tokens.islandNotificationIcon
                height: Tokens.islandNotificationIcon
                radius: Tokens.radiusIslandIcon
                color: Colors.secondary

                Icon {
                    anchors.centerIn: parent
                    visible: !appIconImage.visible && !imageItem.visible
                    name: "notifications"
                    filled: true
                    size: Tokens.iconOsd
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
                width: parent.width - Tokens.islandNotificationIcon - close.width - parent.spacing * 2

                StyledText {
                    width: parent.width
                    style: "bodySm"
                    color: Colors.on.islandVariant
                    elide: Text.ElideRight
                    text: `${root.notification?.appName || "App"} · ${Notifications.ago(root.notification)}`
                }
                StyledText {
                    width: parent.width
                    style: "islandNotificationTitle"
                    color: Colors.on.island
                    elide: Text.ElideRight
                    text: root.notification?.summary ?? ""
                }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    style: "bodyMd"
                    color: Colors.on.island
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: root.notification?.body ?? ""
                }
            }

            IslandButton {
                id: close
                width: Tokens.chipHeight
                height: Tokens.chipHeight
                color: "transparent"
                icon: "close"
                filled: false
                iconSize: Tokens.iconSm
                contentColor: Colors.on.islandVariant
                label: "Dismiss"
                onClicked: Notifications.dismiss(root.notification)
            }
        }

        // ── inline reply ──
        Rectangle {
            width: parent.width
            height: Tokens.replyFieldHeight
            visible: root.notification?.hasInlineReply ?? false
            radius: height / 2
            color: Colors.islandContainer
            border.width: reply.activeFocus ? 2 : 0
            border.color: Colors.islandAccent

            TextInput {
                id: reply
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space4
                anchors.right: send.left
                anchors.rightMargin: Tokens.space2
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.on.island
                selectionColor: Colors.islandContainerHigh
                font: Type.font("toastLabel")
                clip: true
                activeFocusOnTab: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Reply"
                onActiveFocusChanged: if (activeFocus) root.wantsKeyboard()
                onAccepted: {
                    Notifications.reply(root.notification, text);
                    text = "";
                }
                // Clicking the field asks the Island for keyboard focus first.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onPressed: event => {
                        root.wantsKeyboard();
                        reply.forceActiveFocus();
                        event.accepted = false;
                    }
                }
            }
            StyledText {
                anchors.left: reply.left
                anchors.verticalCenter: parent.verticalCenter
                visible: reply.text === ""
                style: "toastLabel"
                weight: Type.spec("bodyMd").weight
                color: Colors.on.islandVariant
                text: root.notification?.inlineReplyPlaceholder || "Reply…"
            }

            IslandButton {
                id: send
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space1
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.chipHeight
                height: Tokens.chipHeight
                radius: Tokens.radiusTileSm
                color: Colors.islandAccent
                contentColor: Colors.on.islandAccent
                icon: "arrow_upward"
                iconSize: Tokens.iconSm
                label: "Send reply"
                enabledState: reply.text.trim() !== ""
                onClicked: {
                    Notifications.reply(root.notification, reply.text);
                    reply.text = "";
                }
            }
        }

        // ── actions ──
        Flow {
            width: parent.width
            spacing: Tokens.space2
            visible: !(root.notification?.hasInlineReply ?? false) && root.actions.length > 0
            Repeater {
                model: root.actions
                IslandButton {
                    id: actionButton
                    required property var modelData
                    required property int index
                    width: actionLabel.implicitWidth + Tokens.space3_5 * 2
                    height: Tokens.chipHeight
                    color: index === 0 ? Colors.islandAccent : Colors.islandContainerHigh
                    contentColor: index === 0 ? Colors.on.islandAccent : Colors.on.island
                    label: modelData.text
                    onClicked: Notifications.invoke(root.notification, modelData)
                    StyledText {
                        id: actionLabel
                        anchors.centerIn: parent
                        style: "chipLabel"
                        color: actionButton.contentColor
                        text: actionButton.modelData.text
                    }
                }
            }
        }
    }
}
