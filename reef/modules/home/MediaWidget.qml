import QtQuick
import qs.theme
import qs.services
import qs.components

// Media home widget (screens/Home): a radius-2xl squircle on primary-container with the
// artwork in a 4-leaf clover, title, artist, wavy progress and a play/pause button.
Rectangle {
    id: root

    readonly property real outlineRadius: radius
    property bool interactive: true

    implicitWidth: Tokens.widgetMediaWidth
    implicitHeight: Tokens.widgetMediaHeight
    radius: Tokens.radius2xl
    color: Colors.primaryContainer

    Accessible.role: Accessible.Grouping
    Accessible.name: Media.active ? `Media, ${Media.title}` + (Media.artist ? `, ${Media.artist}` : "") : "Media, nothing playing"

    Row {
        x: Tokens.space4
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Tokens.space4 - Tokens.space5
        spacing: Tokens.space4

        ShapeImage {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.widgetMediaArt
            height: Tokens.widgetMediaArt
            shape: "clover4"
            source: Media.artUrl
            icon: "music_note"
            iconSize: Tokens.widgetMediaArtIcon
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.widgetMediaArt - play.width - parent.spacing * 2
            spacing: Tokens.space2_5

            Column {
                width: parent.width
                StyledText {
                    width: parent.width
                    style: "widgetTitle"
                    elide: Text.ElideRight
                    color: Colors.on.primaryContainer
                    text: Media.active ? Media.title : "Nothing playing"
                }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    style: "rowLabel"
                    elide: Text.ElideRight
                    color: Colors.on.primaryContainer
                    opacity: Tokens.widgetSecondaryOpacity
                    text: Media.artist
                }
            }
            WavyProgress {
                width: parent.width
                height: Tokens.waveHeight
                visible: Media.active
                progress: Media.progress
                playing: Media.playing
                interactive: root.interactive && Media.canSeek
                color: Colors.on.primaryContainer
                trackColor: Qt.alpha(Colors.on.primaryContainer, Tokens.widgetTrackOpacity)
                onSeek: f => Media.seekTo(f)
            }
        }

        Item {
            id: play
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.widgetMediaButton
            height: Tokens.widgetMediaButton
            enabled: root.interactive && Media.active
            opacity: Media.active ? 1 : Tokens.disabledOpacity

            activeFocusOnTab: enabled
            Accessible.role: Accessible.Button
            Accessible.name: Media.playing ? "Pause" : "Play"
            Keys.onReturnPressed: Media.togglePlaying()
            Keys.onSpacePressed: Media.togglePlaying()

            Spring {
                id: corner
                spec: Motion.spatialFast
                target: playMouse.pressed ? Tokens.radiusMd : Tokens.radiusPlay
            }
            Rectangle {
                anchors.fill: parent
                radius: corner.value
                color: Colors.on.primaryContainer
                border.width: play.activeFocus ? 2 : 0
                border.color: Colors.primary
            }
            Icon {
                anchors.centerIn: parent
                name: Media.playing ? "pause" : "play_arrow"
                filled: true
                size: Tokens.widgetMediaButtonIcon
                color: Colors.primaryContainer
            }
            MouseArea {
                id: playMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.togglePlaying()
            }
        }
    }
}
