import QtQuick
import qs.theme
import qs.services

// Five-bar waveform for the collapsed media activity. Driven by cava through
// services/Visualizer; with the visualizer off it rests in the mockup's shape.
Row {
    id: root

    property color color: Colors.islandAccent
    // Resting heights from parts/Island-Rest (fractions of visualizer-height).
    readonly property var resting: [0.375, 0.875, 0.5625, 1, 0.4375]

    spacing: Tokens.visualizerBar
    height: Tokens.visualizerHeight

    Component.onCompleted: Visualizer.users++
    Component.onDestruction: Visualizer.users--

    Repeater {
        model: 5
        Rectangle {
            id: bar
            required property int index
            readonly property real level: Visualizer.running ? Math.max(0.3, Visualizer.levels[index] ?? 0) : root.resting[index]
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.visualizerBar
            height: Math.max(width, hSpring.value * Tokens.visualizerHeight)
            radius: Tokens.radiusXs / 2
            color: root.color
            Spring {
                id: hSpring
                spec: Motion.spatialFast
                target: bar.level
            }
        }
    }
}
