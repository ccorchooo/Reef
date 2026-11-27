import QtQuick
import qs.theme
import qs.services
import qs.components

// Settings → Coral: where each part runs (chat, listening, speaking: on this computer or
// in the cloud), the local server, the cloud service (Groq by default) and its key, and
// voice. The key is saved to ~/.config/reef/keys/cloud (only you can read it), never to
// config.json; the field never shows it back.
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var coral: Config.options.coral
    readonly property var where: [{ value: "local", label: "This computer" }, { value: "cloud", label: "Cloud" }]

    component Choice: Column {
        id: choice
        property string text: ""
        property string current: ""
        signal selected(string value)
        width: parent.width
        spacing: Tokens.space2
        StyledText {
            width: parent.width
            style: "rowLabel"
            text: choice.text
        }
        SegmentedButtons {
            width: parent.width
            label: choice.text
            options: root.where
            current: choice.current
            onSelected: v => choice.selected(v)
        }
    }

    SettingsSection {
        width: parent.width
        title: "Where Coral runs"
        Choice {
            text: "Chat"
            current: root.coral.chat
            onSelected: v => Config.options.coral.chat = v
        }
        Choice {
            text: "Listening (speech to text)"
            current: root.coral.listen
            onSelected: v => Config.options.coral.listen = v
        }
        Choice {
            text: "Speaking (text to speech)"
            current: root.coral.speech
            onSelected: v => Config.options.coral.speech = v
        }
    }

    SettingsSection {
        width: parent.width
        title: "Cloud"
        TextFieldRow {
            width: parent.width
            text: "Endpoint"
            placeholder: "https://api.groq.com/openai/v1"
            value: root.coral.cloud.endpoint
            onCommitted: v => Config.options.coral.cloud.endpoint = Coral.base(v)
        }
        TextFieldRow {
            id: keyField
            width: parent.width
            secret: true
            text: Coral.hasKey ? "API key (saved; type a new one to replace it)" : "API key"
            placeholder: Coral.hasKey ? "••••••••" : "gsk_…"
            value: ""
            onCommitted: v => {
                if (v.trim() !== "")
                    Coral.saveKey(v);
                clear();
            }
        }
        PillButton {
            visible: Coral.hasKey
            text: "Forget the key"
            onClicked: Coral.saveKey("")
        }
        TextFieldRow {
            width: parent.width
            text: "Or read the key from this environment variable"
            placeholder: "GROQ_API_KEY"
            value: root.coral.cloud.keyEnv
            onCommitted: v => {
                Config.options.coral.cloud.keyEnv = v.trim();
                Coral.checkKey();
            }
        }
        TextFieldRow {
            width: parent.width
            text: "Chat model"
            placeholder: "openai/gpt-oss-120b"
            value: root.coral.cloud.model
            onCommitted: v => Config.options.coral.cloud.model = v.trim()
        }
        TextFieldRow {
            width: parent.width
            text: "Speech-to-text model"
            placeholder: "whisper-large-v3-turbo"
            value: root.coral.cloud.listenModel
            onCommitted: v => Config.options.coral.cloud.listenModel = v.trim()
        }
        TextFieldRow {
            width: parent.width
            text: "Text-to-speech model"
            placeholder: "canopylabs/orpheus-v1-english"
            value: root.coral.cloud.speechModel
            onCommitted: v => Config.options.coral.cloud.speechModel = v.trim()
        }
        TextFieldRow {
            width: parent.width
            text: "Cloud voice"
            placeholder: "troy"
            value: root.coral.cloud.speechVoice
            onCommitted: v => Config.options.coral.cloud.speechVoice = v.trim()
        }
    }

    SettingsSection {
        width: parent.width
        title: "This computer"
        TextFieldRow {
            width: parent.width
            text: "Local server"
            placeholder: "http://localhost:11434/v1"
            value: root.coral.local.endpoint
            onCommitted: v => Config.options.coral.local.endpoint = Coral.base(v)
        }
        TextFieldRow {
            width: parent.width
            text: "Local model"
            placeholder: "The server's first model"
            value: root.coral.local.model
            onCommitted: v => Config.options.coral.local.model = v.trim()
        }
    }

    SettingsSection {
        width: parent.width
        title: "Conversation"
        SwitchRow {
            width: parent.width
            text: "Offer actions"
            description: "Buttons under a reply that change a setting or open something. They run only when pressed."
            checked: root.coral.actions
            onToggled: Config.options.coral.actions = !checked
        }
        PillButton {
            text: "Ask Coral"
            onClicked: Actions.islandRequested("coral")
        }
    }

    SettingsSection {
        width: parent.width
        title: "Voice"
        SwitchRow {
            width: parent.width
            text: "Voice"
            description: "Talk to Coral with Super+A and hear it answer."
            checked: root.coral.voice
            onToggled: Config.options.coral.voice = !checked
        }
        SwitchRow {
            width: parent.width
            visible: root.coral.voice
            text: "Speak replies"
            description: Object.keys(CoralVoice.voices).length > 0 ? "Local voices: " + Object.keys(CoralVoice.voices).join(", ") + "." : ""
            checked: root.coral.speak
            onToggled: Config.options.coral.speak = !checked
        }
        Column {
            width: parent.width
            visible: root.coral.voice
            spacing: Tokens.space2
            StyledText {
                width: parent.width
                style: "rowLabel"
                text: "Listening language"
            }
            SegmentedButtons {
                width: parent.width
                label: "Listening language"
                options: [{ value: "auto", label: "Detect" }, { value: "es", label: "Español" }, { value: "en", label: "English" }]
                current: root.coral.listenLanguage
                onSelected: v => Config.options.coral.listenLanguage = v
            }
        }
        SwitchRow {
            width: parent.width
            visible: root.coral.voice
            text: "Keep listening after a reply"
            description: "A few seconds for a follow-up, then the Pearl folds away and the reply waits on the Island."
            checked: root.coral.followUp
            onToggled: Config.options.coral.followUp = !checked
        }
        SwitchRow {
            width: parent.width
            visible: root.coral.voice
            text: "Wake word"
            description: "Say “Hey Coral” or “Oye Coral”. The microphone stays on while this is on."
            checked: root.coral.wake
            onToggled: Config.options.coral.wake = !checked
        }
        Choice {
            visible: root.coral.voice && root.coral.wake
            text: "Listen for it on"
            current: root.coral.wakeWith
            onSelected: v => Config.options.coral.wakeWith = v
        }
        StyledText {
            width: parent.width
            visible: root.coral.voice && root.coral.wake
            wrapMode: Text.Wrap
            style: "bodySm"
            color: Colors.on.surfaceVariant
            text: CoralWake.missing !== "" ? "Wake word needs " + CoralWake.missing + "."
                : root.coral.wakeWith === "cloud" ? "Each short burst of speech near the microphone is sent to " + Coral.base(root.coral.cloud.endpoint).replace(/^https?:\/\//, "") + " to check for the phrase."
                : "Checked on this computer with whisper's tiny model."
        }
        StyledText {
            width: parent.width
            visible: root.coral.voice && CoralVoice.missing !== ""
            wrapMode: Text.Wrap
            style: "bodySm"
            color: Colors.on.surfaceVariant
            text: "Missing: " + CoralVoice.missing + "."
        }
        PillButton {
            visible: root.coral.voice
            text: "Look again"
            onClicked: {
                CoralVoice.rescan();
                Coral.checkKey();
            }
        }
    }
}
