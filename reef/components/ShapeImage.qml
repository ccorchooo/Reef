import QtQuick
import QtQuick.Effects
import qs.theme

// An image (album art) clipped to an M3E shape, with a colored shape and icon when
// there's no image.
//
//   ShapeImage { shape: "cookie12"; source: Media.artUrl; color: Colors.tertiaryContainer
//                icon: "music_note"; iconColor: Colors.on.tertiaryContainer }
Item {
    id: root

    property string shape: "circle"
    property url source: ""
    property color color: Colors.tertiaryContainer
    property string icon: ""
    property real iconSize: Tokens.iconLg
    property color iconColor: Colors.on.tertiaryContainer
    readonly property bool hasImage: img.status === Image.Ready

    ShapeItem {
        anchors.fill: parent
        radii: Shapes.sample(root.shape, width, height)
        color: root.color
    }

    Icon {
        anchors.centerIn: parent
        visible: !root.hasImage && root.icon !== ""
        name: root.icon
        size: root.iconSize
        filled: true
        color: root.iconColor
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        visible: false
    }

    ShapeItem {
        id: mask
        anchors.fill: parent
        radii: Shapes.sample(root.shape, width, height)
        color: "white"
        layer.enabled: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.hasImage
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
}
