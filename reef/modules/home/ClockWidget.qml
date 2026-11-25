import QtQuick
import qs.theme
import qs.components

// Clock home widget (screens/Home): the analog clock in a circle.
AnalogClock {
    readonly property real outlineRadius: width / 2
    property bool interactive: true
    size: Tokens.widgetClockSize
}
