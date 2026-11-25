import QtQuick
import qs.theme
import qs.services
import qs.components

// Weather home widget (screens/Home): a 12-sided cookie on tertiary-container with the
// condition icon, the temperature (ROND 100) and the description.
Item {
    id: root

    readonly property real outlineRadius: width / 2
    property bool interactive: true

    implicitWidth: Tokens.widgetWeatherSize
    implicitHeight: Tokens.widgetWeatherSize

    Component.onCompleted: Weather.hold()
    Component.onDestruction: Weather.release()

    Accessible.role: Accessible.StaticText
    Accessible.name: Weather.ready ? `Weather, ${Weather.temperature}, ${Weather.description}` : "Weather"

    ShapeItem {
        anchors.fill: parent
        radii: Shapes.sample("cookie12", width, height)
        color: Colors.tertiaryContainer
    }

    Column {
        anchors.centerIn: parent

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: Weather.ready ? Weather.icon : "cloud"
            filled: true
            size: Tokens.widgetWeatherIcon
            color: Colors.on.tertiaryContainer
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            style: "widgetTemperature"
            rond: 100
            color: Colors.on.tertiaryContainer
            text: Weather.ready ? Weather.temperature : "–°"
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, root.width - Tokens.space12)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            style: "optionLabel"
            color: Colors.on.tertiaryContainer
            text: Weather.ready ? Weather.description : Weather.error
        }
    }
}
