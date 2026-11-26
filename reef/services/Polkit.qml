pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit

// Reef as the polkit authentication agent (SURFACES.md → Authentication dialog).
// Only one agent can be registered per session: while another runs (polkit-gnome,
// hyprpolkitagent) `registered` stays false and that agent keeps answering.
// Settings → Power & session → "Answer polkit prompts" (session.polkitAgent).
Singleton {
    id: root

    readonly property var agent: loader.item
    readonly property bool registered: agent?.isRegistered ?? false
    readonly property var flow: agent?.flow ?? null
    readonly property bool active: !!flow && !flow.isCompleted
    // The monitor that had focus when the request came in; the dialog opens there.
    property string screenName: ""

    LazyLoader {
        id: loader
        active: Config.options.session.polkitAgent

        PolkitAgent {
            onAuthenticationRequestStarted: root.screenName = Monitors.focused
            onIsRegisteredChanged: {
                if (!isRegistered)
                    console.info("Polkit: another agent answers polkit prompts; Reef's dialog is off");
            }
        }
    }
}
