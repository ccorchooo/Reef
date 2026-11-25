import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Coral: where the assistant's model lives. Any OpenAI-compatible endpoint,
// local ones included. The key is read from an environment variable, never stored.
Column {
    id: root

    spacing: Tokens.settingsGap

    StyledText {
        width: parent.width
        style: "bodyMd"
        color: Colors.on.surfaceVariant
        wrapMode: Text.Wrap
        text: "Coral isn't here yet. These settings are kept for when it arrives."
    }

    SettingsSection {
        width: parent.width
        title: "Model"
        TextFieldRow {
            width: parent.width
            text: "Endpoint"
            placeholder: "http://localhost:11434/v1"
            value: Config.options.coral.endpoint
            onCommitted: v => Config.options.coral.endpoint = v.trim()
        }
        TextFieldRow {
            width: parent.width
            text: "Model"
            placeholder: "The endpoint's default"
            value: Config.options.coral.model
            onCommitted: v => Config.options.coral.model = v.trim()
        }
        TextFieldRow {
            width: parent.width
            text: "Environment variable with the API key"
            placeholder: "OPENAI_API_KEY"
            value: Config.options.coral.apiKeyEnv
            onCommitted: v => Config.options.coral.apiKeyEnv = v.trim()
        }
    }
    SettingsSection {
        width: parent.width
        title: "Voice"
        SwitchRow {
            width: parent.width
            text: "Voice"
            description: "Talk to Coral and hear it answer."
            checked: Config.options.coral.voice
            onToggled: Config.options.coral.voice = !checked
        }
    }
}
