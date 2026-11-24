import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// The hover peek (parts/Island-Rest, screens/Working): the current activity at a
// glance with its main control. 380×64, radius-xl, shadow-island.
Item {
    id: root

    property Activity activity: null
    readonly property bool isMedia: activity?.key === "media"
    readonly property var action: activity?.actions?.[0] ?? null

    Row {
        anchors.fill: parent
        anchors.leftMargin: Tokens.space2_5
        anchors.rightMargin: Tokens.space3
        spacing: Tokens.space3

        ClippingRectangle {
            id: art
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.islandArtMd
            height: Tokens.islandArtMd
            radius: Tokens.radiusMd
            color: root.isMedia ? Colors.tertiaryContainer : Colors.islandContainerHigh

            Icon {
                anchors.centerIn: parent
                visible: root.activity?.leading !== "dot" && (!root.isMedia || cover.status !== Image.Ready)
                name: root.isMedia ? "music_note" : (root.activity?.icon ?? "")
                filled: true
                size: Tokens.iconLg
                color: root.isMedia ? Colors.on.tertiaryContainer : (root.activity?.iconColor ?? Colors.islandAccent)
            }
            Rectangle {
                anchors.centerIn: parent
                visible: root.activity?.leading === "dot"
                width: Tokens.recordingDot
                height: Tokens.recordingDot
                radius: width / 2
                color: root.activity?.dotColor ?? Colors.error
            }
            Image {
                id: cover
                anchors.fill: parent
                visible: root.isMedia && status === Image.Ready
                source: root.isMedia ? Media.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Tokens.islandArtMd * 2
                sourceSize.height: Tokens.islandArtMd * 2
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - art.width - (button.visible ? button.width + parent.spacing : 0) - parent.spacing

            StyledText {
                width: parent.width
                style: "islandTitle"
                color: Colors.on.island
                elide: Text.ElideRight
                text: root.activity?.title ?? ""
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: root.activity?.subtitleMono ? "monoSm" : "bodySm"
                color: Colors.on.islandVariant
                elide: Text.ElideRight
                text: root.activity?.subtitle ?? ""
            }
        }

        IslandButton {
            id: button
            anchors.verticalCenter: parent.verticalCenter
            visible: root.action !== null
            color: root.action?.tone === "error" ? Colors.error : Colors.islandAccent
            contentColor: root.action?.tone === "error" ? Colors.on.error : Colors.on.islandAccent
            icon: root.action?.icon ?? ""
            label: root.action?.label ?? ""
            onClicked: root.action?.run()
        }
    }
}
