import QtQuick
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.components

// The Island's Now tab (parts/Island-Now): media with wavy progress and controls,
// then any other live activities (timer, recording) as rows.
Column {
    id: root

    spacing: Tokens.space3_5

    // ── media ───────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: Tokens.space3_5
        visible: Media.active

        Row {
            width: parent.width
            spacing: Tokens.space3_5

            ShapeImage {
                id: art
                width: Tokens.islandArtLg
                height: Tokens.islandArtLg
                shape: "cookie12"
                source: Media.artUrl
                color: Colors.tertiaryContainer
                icon: "music_note"
                iconSize: Tokens.iconLg + Tokens.space1
                iconColor: Colors.on.tertiaryContainer
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - art.width - output.width - parent.spacing * 2
                spacing: Tokens.spaceHalf

                StyledText {
                    width: parent.width
                    style: "titleMdEmphasized"
                    color: Colors.on.island
                    elide: Text.ElideRight
                    text: Media.title
                }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    style: "bodyMd"
                    color: Colors.on.islandVariant
                    elide: Text.ElideRight
                    text: [Media.artist, Media.album].filter(s => s).join(" · ")
                }
            }

            IslandButton {
                id: output
                anchors.verticalCenter: parent.verticalCenter
                icon: "speaker"
                filled: false
                label: "Output device"
                onClicked: Actions.run("audioOutput")
            }
        }

        Row {
            width: parent.width
            spacing: Tokens.space2_5

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandTimeWidth
                style: "monoSm"
                color: Colors.on.islandVariant
                text: Media.formatTime(Media.position)
            }
            WavyProgress {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.islandTimeWidth * 2 - parent.spacing * 2
                progress: Media.progress
                playing: Media.playing
                interactive: Media.canSeek
                onSeek: f => Media.seekTo(f)
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandTimeWidth
                horizontalAlignment: Text.AlignRight
                style: "monoSm"
                color: Colors.on.islandVariant
                text: Media.length > 0 ? Media.formatTime(Media.length) : ""
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.space5

            IslandButton {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandControl
                height: Tokens.islandControl
                color: "transparent"
                icon: "shuffle"
                filled: false
                contentColor: Media.shuffle ? Colors.islandAccent : Colors.on.islandVariant
                enabledState: Media.shuffleSupported
                label: Media.shuffle ? "Shuffle on" : "Shuffle off"
                onClicked: Media.toggleShuffle()
            }
            IslandButton {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandControl
                height: Tokens.islandControl
                icon: "skip_previous"
                enabledState: Media.canGoPrevious
                label: "Previous"
                onClicked: Media.previous()
            }
            IslandButton {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandPlayWidth
                height: Tokens.islandPlayHeight
                radius: Tokens.radiusPlay
                color: Colors.islandAccent
                contentColor: Colors.on.islandAccent
                icon: Media.playing ? "pause" : "play_arrow"
                iconSize: Tokens.iconLg + Tokens.space1
                label: Media.playing ? "Pause" : "Play"
                onClicked: Media.togglePlaying()
            }
            IslandButton {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandControl
                height: Tokens.islandControl
                icon: "skip_next"
                enabledState: Media.canGoNext
                label: "Next"
                onClicked: Media.next()
            }
            IslandButton {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.islandControl
                height: Tokens.islandControl
                color: "transparent"
                icon: Media.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                filled: false
                contentColor: Media.loopState !== MprisLoopState.None ? Colors.islandAccent : Colors.on.islandVariant
                enabledState: Media.loopSupported
                label: Media.loopState === MprisLoopState.Track ? "Repeat one" : Media.loopState === MprisLoopState.Playlist ? "Repeat all" : "Repeat off"
                onClicked: Media.cycleLoop()
            }
        }
    }

    // ── nothing going on ────────────────────────────────────────
    ActivityRow {
        visible: !Media.active && rows.count === 0
        icon: "music_note"
        iconColor: Colors.on.islandVariant
        label: "Nothing playing"
        labelColor: Colors.on.islandVariant
    }

    // ── every other live activity, in priority order ────────────
    Repeater {
        id: rows
        model: IslandState.liveActivities.filter(a => a.key !== "media")

        ActivityRow {
            id: row
            required property Activity modelData
            icon: modelData.leading === "dot" ? "" : modelData.icon
            iconColor: modelData.iconColor
            label: modelData.title + (modelData.value === "" && modelData.subtitle ? " · " + modelData.subtitle : "")
            value: modelData.value
            valueColor: modelData.textColor
            Accessible.name: modelData.spoken

            Rectangle {
                parent: row.dotSlot
                anchors.centerIn: parent
                visible: row.modelData.leading === "dot"
                width: Tokens.recordingDot
                height: Tokens.recordingDot
                radius: width / 2
                color: row.modelData.dotColor
            }

            Repeater {
                model: row.modelData.actions
                IslandButton {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.islandButtonSm
                    height: Tokens.islandButtonSm
                    iconSize: Tokens.iconSm
                    color: modelData.tone === "error" ? Colors.error : Colors.islandContainerHigh
                    contentColor: modelData.tone === "error" ? Colors.on.error : Colors.on.island
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: modelData.run()
                }
            }
        }
    }

    // A live-activity row on island-container (parts/Island-Now: the timer row).
    component ActivityRow: Rectangle {
        id: row
        property string icon
        property color iconColor: Colors.islandAccent
        property string label
        property color labelColor: Colors.on.island
        property string value
        property color valueColor: Colors.islandAccent
        default property alias trailing: trailingRow.data
        readonly property Item dotSlot: iconSlot

        width: root.width
        implicitHeight: Math.max(Tokens.islandButtonSm, labelText.implicitHeight) + Tokens.space2_5 * 2
        radius: Tokens.radiusLg
        color: Colors.islandContainer

        Row {
            anchors.fill: parent
            anchors.leftMargin: Tokens.space3
            anchors.rightMargin: Tokens.space3
            spacing: Tokens.space3

            Item {
                id: iconSlot
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.iconLg
                height: Tokens.iconLg
                Icon {
                    anchors.centerIn: parent
                    visible: row.icon !== ""
                    name: row.icon
                    filled: true
                    size: Tokens.iconLg
                    color: row.iconColor
                }
            }

            StyledText {
                id: labelText
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconSlot.width - valueText.implicitWidth - trailingRow.implicitWidth - parent.spacing * 3
                style: "bodyMd"
                color: row.labelColor
                elide: Text.ElideRight
                text: row.label
            }

            StyledText {
                id: valueText
                anchors.verticalCenter: parent.verticalCenter
                style: "monoLg"
                color: row.valueColor
                text: row.value
            }

            Row {
                id: trailingRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space2
            }
        }
    }
}
