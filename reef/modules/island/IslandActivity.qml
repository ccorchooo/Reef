import QtQuick
import qs.theme
import qs.services
import qs.components

// A collapsed live activity (parts/Island-Rest): a leading glyph on the left
// (icon, red dot, or media artwork) and a readout on the right (text or waveform).
// Used by the Island and by the secondary pill below it.
Item {
    id: root

    property Activity activity: null
    readonly property bool hasActivity: activity !== null

    // Paddings from the mockup: artwork sits closer to the edge, a dot a little further.
    readonly property real startPadding: !hasActivity ? 0
        : activity.leading === "art" ? Tokens.cayPaddingTight
        : activity.leading === "dot" ? Tokens.space3 : Tokens.space2_5
    readonly property real endPadding: Tokens.space3_5

    Item {
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: root.startPadding
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height

        Icon {
            visible: root.hasActivity && root.activity.leading === "icon"
            name: root.activity?.icon ?? ""
            filled: true
            size: Tokens.iconSm
            color: root.activity?.iconColor ?? Colors.islandAccent
        }
        Rectangle {
            visible: root.hasActivity && root.activity.leading === "dot"
            width: Tokens.recordingDot
            height: Tokens.recordingDot
            radius: width / 2
            color: root.activity?.dotColor ?? Colors.error
        }
        ShapeImage {
            visible: root.hasActivity && root.activity.leading === "art"
            width: Tokens.islandArtSm
            height: Tokens.islandArtSm
            shape: "cookie6"
            source: visible ? Media.artUrl : ""
            color: Colors.tertiaryContainer
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: root.endPadding
        anchors.verticalCenter: parent.verticalCenter
        // Leave room for the glyph on the left.
        width: Math.min(implicitWidth, root.width - root.startPadding - lead.width - Tokens.space3 - root.endPadding)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        visible: root.hasActivity && root.activity.trailing === "text"
        style: root.activity?.textMono ? "monoMd" : "labelMd"
        text: root.activity?.text ?? ""
        color: root.activity?.textColor ?? Colors.on.island
    }

    Loader {
        anchors.right: parent.right
        anchors.rightMargin: root.endPadding
        anchors.verticalCenter: parent.verticalCenter
        // Only run the visualizer while a waveform is showing.
        active: root.hasActivity && root.activity.trailing === "waveform" && root.visible
        sourceComponent: MiniWaveform {}
    }
}
