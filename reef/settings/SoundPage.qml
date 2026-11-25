import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.menus

// Settings → Sound: volume and outputs (the audio quick menu), and the microphone.
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
}
