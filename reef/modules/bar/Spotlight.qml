import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// Spotlight cay (SURFACES.md → Bar): the special widget. For now it shows the current
// media; it folds away when nothing is playing or when Settings → Bar → Show Spotlight is off.
Cay {
    id: root

    readonly property bool shown: Config.options.bar.showSpotlight && Media.active

    leftPadding: shown ? Tokens.cayPaddingTight : 0
    // The play button's hit area is wider than its glyph; keep the glyph cay-padding from the edge.
    rightPadding: shown ? Tokens.cayPadding - (Tokens.cayItemSm - Tokens.iconSm) / 2 : 0
    contentWidth: shown ? row.implicitWidth : 0
    visible: width > 0.5
    opacity: fade.value

    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.shown ? 1 : 0
    }

    Accessible.role: Accessible.Grouping
    Accessible.name: `Spotlight: ${Media.title}${Media.artist ? ", " + Media.artist : ""}`

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space2

        ClippingRectangle {
            id: art
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.cayItemSm
            height: Tokens.cayItemSm
            radius: Tokens.radiusArtSm
            color: Colors.tertiaryContainer

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                name: "music_note"
                size: Tokens.iconXs
                filled: true
                color: Colors.on.tertiaryContainer
            }

            Image {
                id: cover
                anchors.fill: parent
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Tokens.cayItemSm * 2
                sourceSize.height: Tokens.cayItemSm * 2
                visible: status === Image.Ready
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(Tokens.spotlightTextMax, Math.max(titleText.implicitWidth, artistText.implicitWidth))

            StyledText {
                id: titleText
                width: parent.width
                style: "barTitle"
                elide: Text.ElideRight
                text: Media.title
            }
            StyledText {
                id: artistText
                width: parent.width
                visible: text !== ""
                style: "barSubtitle"
                color: Colors.on.surfaceVariant
                elide: Text.ElideRight
                text: Media.artist
            }
        }

        CayButton {
            anchors.verticalCenter: parent.verticalCenter
            size: Tokens.cayItemSm
            icon: Media.playing ? "pause" : "play_arrow"
            iconSize: Tokens.iconSm
            filled: true
            contentColor: Colors.on.surface
            label: Media.playing ? "Pause" : "Play"
            onClicked: Media.togglePlaying()
        }
    }
}
