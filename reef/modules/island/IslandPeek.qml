import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// The hover peek (parts/Island-Rest, screens/Working): the current activity at a glance
// with its main control. 380×64, radius-xl, shadow-island.
Item {
    id: root

    required property string kind   // "media" | "timer" | "recording"

    readonly property string title: kind === "media" ? Media.title
        : kind === "timer" ? Countdown.label
        : "Recording"
    readonly property string subtitle: kind === "media" ? Media.artist
        : kind === "timer" ? Countdown.text + (Countdown.paused ? " · Paused" : "")
        : Recording.text

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
            color: root.kind === "media" ? Colors.tertiaryContainer : Colors.islandContainerHigh

            Icon {
                anchors.centerIn: parent
                visible: root.kind !== "media" || cover.status !== Image.Ready
                name: root.kind === "media" ? "music_note" : root.kind === "timer" ? "timer" : ""
                filled: true
                size: Tokens.iconLg
                color: root.kind === "media" ? Colors.on.tertiaryContainer : Colors.islandAccent
            }
            Rectangle {
                anchors.centerIn: parent
                visible: root.kind === "recording"
                width: Tokens.recordingDot
                height: Tokens.recordingDot
                radius: width / 2
                color: Colors.error
            }
            Image {
                id: cover
                anchors.fill: parent
                visible: root.kind === "media" && status === Image.Ready
                source: root.kind === "media" ? Media.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Tokens.islandArtMd * 2
                sourceSize.height: Tokens.islandArtMd * 2
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - art.width - button.width - parent.spacing * 2

            StyledText {
                width: parent.width
                style: "islandTitle"
                color: Colors.on.island
                elide: Text.ElideRight
                text: root.title
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                style: root.kind === "media" ? "bodySm" : "monoSm"
                color: Colors.on.islandVariant
                elide: Text.ElideRight
                text: root.subtitle
            }
        }

        IslandButton {
            id: button
            anchors.verticalCenter: parent.verticalCenter
            color: root.kind === "recording" ? Colors.error : Colors.islandAccent
            contentColor: root.kind === "recording" ? Colors.on.error : Colors.on.islandAccent
            icon: root.kind === "recording" ? "stop"
                : root.kind === "timer" ? (Countdown.paused ? "play_arrow" : "pause")
                : (Media.playing ? "pause" : "play_arrow")
            label: root.kind === "recording" ? "Stop recording"
                : root.kind === "timer" ? (Countdown.paused ? "Resume timer" : "Pause timer")
                : (Media.playing ? "Pause" : "Play")
            onClicked: {
                if (root.kind === "recording")
                    Recording.stop();
                else if (root.kind === "timer")
                    Countdown.toggle();
                else
                    Media.togglePlaying();
            }
        }
    }
}
