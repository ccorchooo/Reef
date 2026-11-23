import QtQuick
import qs.theme
import qs.services
import qs.components

// The collapsed live activity inside the resting pill (parts/Island-Rest):
// timer, media (artwork + mini waveform) or recording (red dot + elapsed time).
Item {
    id: root

    required property string kind   // "timer" | "media" | "recording"

    readonly property real startPadding: kind === "media" ? Tokens.cayPaddingTight : kind === "timer" ? Tokens.space2_5 : Tokens.space3
    readonly property real endPadding: Tokens.space3_5

    // ── timer ──
    Item {
        anchors.fill: parent
        visible: root.kind === "timer"
        Icon {
            anchors.left: parent.left
            anchors.leftMargin: root.startPadding
            anchors.verticalCenter: parent.verticalCenter
            name: "timer"
            filled: true
            size: Tokens.iconSm
            color: Colors.islandAccent
        }
        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: root.endPadding
            anchors.verticalCenter: parent.verticalCenter
            style: "monoMd"
            text: Countdown.text
            color: Countdown.paused ? Colors.on.islandVariant : Colors.islandAccent
        }
    }

    // ── media ──
    Item {
        anchors.fill: parent
        visible: root.kind === "media"
        ShapeImage {
            anchors.left: parent.left
            anchors.leftMargin: root.startPadding
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.islandArtSm
            height: Tokens.islandArtSm
            shape: "cookie6"
            source: Media.artUrl
            color: Colors.tertiaryContainer
        }
        Loader {
            anchors.right: parent.right
            anchors.rightMargin: root.endPadding
            anchors.verticalCenter: parent.verticalCenter
            // Only run the visualizer while this activity is the one showing.
            active: root.kind === "media" && root.visible
            sourceComponent: MiniWaveform {}
        }
    }

    // ── recording ──
    Item {
        anchors.fill: parent
        visible: root.kind === "recording"
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: root.startPadding
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.recordingDot
            height: Tokens.recordingDot
            radius: width / 2
            color: Colors.error
        }
        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: root.endPadding
            anchors.verticalCenter: parent.verticalCenter
            style: "monoMd"
            text: Recording.text
            color: Colors.on.island
        }
    }
}
