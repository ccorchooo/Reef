import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.menus

// Settings → Sound: volume and outputs (the audio quick menu), the microphone, and Reef's
// own sounds (a master toggle, their volume, one switch per category; turning one on
// plays it once).
Column {
    id: root

    spacing: Tokens.settingsGap

    SettingsSection {
        width: parent.width
        AudioMenu {
            width: parent.width
            inSettings: true
        }
    }
    SettingsSection {
        width: parent.width
        title: "Microphone"
        SwitchRow {
            width: parent.width
            text: "Mute microphone"
            checked: Audio.micMuted
            onToggled: Audio.toggleMicMute()
        }
    }
    SettingsSection {
        width: parent.width
        title: "Sounds"
        SwitchRow {
            width: parent.width
            text: "Sounds"
            checked: root.sounds.enabled
            onToggled: Config.options.sounds.enabled = !checked
        }
        SliderRow {
            width: parent.width
            visible: root.sounds.enabled
            text: "Sound volume"
            icon: "volume_down"
            from: 0
            to: 100
            stepSize: 5
            value: Math.round(root.sounds.volume * 100)
            format: v => `${v}%`
            onMoved: v => Config.options.sounds.volume = v / 100
        }
        Repeater {
            model: root.sounds.enabled ? root.categories : []
            SwitchRow {
                required property var modelData
                width: parent.width
                text: modelData.label
                checked: root.sounds[modelData.key]
                onToggled: {
                    const on = !checked;
                    Config.options.sounds[modelData.key] = on;
                    if (on)
                        Sounds.play(modelData.sample);
                }
            }
        }
    }

    readonly property var sounds: Config.options.sounds
    readonly property var categories: [
        { key: "lock", label: "Lock and unlock", sample: "lock" },
        { key: "power", label: "Power actions", sample: "power" },
        { key: "island", label: "Island opens", sample: "island" },
        { key: "shelf", label: "Added to the Shelf", sample: "shelf" },
        { key: "coralListen", label: "Coral listening", sample: "listen" },
        { key: "coralReply", label: "Coral replied", sample: "reply" },
        { key: "notification", label: "Notifications", sample: "notification" }
    ]
}
