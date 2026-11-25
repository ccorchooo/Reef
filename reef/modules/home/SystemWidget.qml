import QtQuick
import qs.theme
import qs.services
import qs.components

// System performance home widget (screens/Home): CPU, memory and GPU temperature as mono
// readouts over thin primary meters, on a surface-container-high radius-xl card.
Rectangle {
    id: root

    readonly property real outlineRadius: radius
    property bool interactive: true

    implicitWidth: Tokens.widgetSystemWidth
    implicitHeight: stats.implicitHeight + Tokens.tilePadding * 2
    radius: Tokens.radiusXl
    color: Colors.surfaceContainerHigh

    Component.onCompleted: SystemStats.hold()
    Component.onDestruction: SystemStats.release()

    Accessible.role: Accessible.StaticText
    Accessible.name: `System, CPU ${SystemStats.cpuText}, memory ${SystemStats.memText}` + (SystemStats.hasGpu ? `, GPU ${SystemStats.gpuText}` : "")

    component Stat: Column {
        id: stat
        property string label
        property string value
        property real fraction
        width: parent.width
        spacing: Tokens.space1

        Item {
            width: parent.width
            height: valueText.implicitHeight
            StyledText {
                style: "widgetStat"
                color: Colors.on.surfaceVariant
                text: stat.label
            }
            StyledText {
                id: valueText
                anchors.right: parent.right
                style: "widgetStat"
                text: stat.value
            }
        }
        Rectangle {
            width: parent.width
            height: Tokens.widgetSystemBar
            radius: height / 2
            color: Colors.surfaceContainerHighest

            Spring {
                id: fill
                spec: Motion.effectsDefault
                target: Math.max(0, Math.min(1, stat.fraction))
            }
            Rectangle {
                width: Math.max(height, parent.width * fill.value)
                height: parent.height
                radius: height / 2
                color: Colors.primary
            }
        }
    }

    Column {
        id: stats
        x: Tokens.tilePadding
        y: Tokens.tilePadding
        width: parent.width - Tokens.tilePadding * 2
        spacing: Tokens.space3

        Stat {
            label: "CPU"
            value: SystemStats.cpuText
            fraction: SystemStats.cpu
        }
        Stat {
            label: "RAM"
            value: SystemStats.memText
            fraction: SystemStats.mem
        }
        Stat {
            visible: SystemStats.hasGpu
            label: "GPU"
            value: SystemStats.gpuText
            fraction: SystemStats.gpuTemp / 100
        }
    }
}
