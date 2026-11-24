import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Audio output quick menu: volume, outputs (the current one on primary-container),
// Sound settings.
Column {
    id: root

    width: Tokens.menuWifiWidth - Tokens.space4 * 2
    spacing: Tokens.space2_5

    StyledText {
        style: "cardTitle"
        text: "Sound"
    }

    ExpressiveSlider {
        width: parent.width
        icon: Audio.icon
        label: "Volume"
        value: Audio.muted ? 0 : Audio.volume
        onMoved: v => Audio.setVolume(v)
    }

    Column {
        width: parent.width
        spacing: Tokens.spaceHalf

        Repeater {
            model: Audio.outputs
            ListRow {
                required property var modelData
                width: root.width
                icon: Audio.outputName(modelData).toLowerCase().includes("hdmi") || Audio.outputName(modelData).toLowerCase().includes("displayport") ? "tv"
                    : modelData.properties?.["device.api"] === "bluez5" ? "headphones" : "speaker"
                title: Audio.outputName(modelData)
                selected: Audio.sink === modelData
                trailingIcon: selected ? "check" : ""
                onClicked: Audio.setOutput(modelData)
            }
        }
    }

    MenuButton {
        width: parent.width
        text: "Sound settings"
        onClicked: {
            PanelState.closeAll();
            Quickshell.execDetached(["pavucontrol"]);
        }
    }
}
