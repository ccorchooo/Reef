import QtQuick
import qs.theme
import qs.components

// Every live activity but media (which the Now tab shows), in priority order, as rows.
// Shown in their own pill under the expanded Island, as wide as it (Island.qml).
Column {
    id: root

    readonly property int count: rows.count
    spacing: Tokens.space2

    Repeater {
        id: rows
        model: IslandState.liveActivities.filter(a => a.key !== "media")

        ActivityRow {
            id: row
            required property Activity modelData
            width: root.width
            icon: modelData.leading === "dot" ? "" : modelData.icon
            iconColor: modelData.iconColor
            label: modelData.title + (modelData.value === "" && modelData.subtitle ? " · " + modelData.subtitle : "")
            value: modelData.value
            valueColor: modelData.textColor
            Accessible.name: modelData.spoken

            Rectangle {
                parent: row.dotSlot
                anchors.centerIn: parent
                visible: row.modelData.leading === "dot"
                width: Tokens.recordingDot
                height: Tokens.recordingDot
                radius: width / 2
                color: row.modelData.dotColor
            }

            Repeater {
                model: row.modelData.actions
                IslandButton {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.islandButtonSm
                    height: Tokens.islandButtonSm
                    iconSize: Tokens.iconSm
                    color: modelData.tone === "error" ? Colors.error : Colors.islandContainerHigh
                    contentColor: modelData.tone === "error" ? Colors.on.error : Colors.on.island
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: modelData.run()
                }
            }
        }
    }
}
