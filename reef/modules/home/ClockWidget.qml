import QtQuick
import qs.theme
import qs.services
import qs.components

// Clock home widget (screens/Home): the analog clock, styled from Settings → Widgets →
// Clock (shape, numbers, ticks, second hand, face color).
AnalogClock {
    readonly property var options: Config.options.home.clock
    // The edit outline is round, except around the squircle.
    readonly property real outlineRadius: shape === "squircle" ? Tokens.radiusLg : width / 2
    property bool interactive: true
    size: Tokens.widgetClockSize
    shape: options.shape
    numbers: options.numbers
    ticks: options.ticks
    seconds: options.seconds
    tone: options.color
}
