pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Which apps are using the microphone, the camera, or capturing the screen,
// read from Pipewire links (a device or portal stream linked into an app's stream).
// Monitoring a speaker (cava, recorders of system audio) doesn't count as the microphone.
Singleton {
    id: root

    readonly property var groups: Pipewire.linkGroups.values

    readonly property var micApps: _apps(cls => cls.startsWith("Audio/Source") || cls === "Audio/Duplex")
    readonly property var cameraApps: _apps(cls => cls === "Video/Source")
    readonly property var screenApps: _apps(cls => cls === "Stream/Output/Video")

    readonly property bool micActive: micApps.length > 0
    readonly property bool cameraActive: cameraApps.length > 0
    readonly property bool sharing: screenApps.length > 0

    function _class(node) {
        return node?.properties?.["media.class"] ?? "";
    }

    function _name(node) {
        const p = node?.properties ?? {};
        return p["application.name"] || p["node.description"] || node?.description || node?.name || "An app";
    }

    function _apps(sourceMatches) {
        const out = [];
        for (const g of groups) {
            if (g.state === PwLinkState.Error || !g.target?.isStream)
                continue;
            if (!sourceMatches(_class(g.source)))
                continue;
            const name = _name(g.target);
            // Coral's wake word is its own, opt-in, always-on listener (Settings → Coral);
            // as an activity it would sit on the Island for good.
            if (name === "Reef wake word")
                continue;
            if (!out.includes(name))
                out.push(name);
        }
        return out;
    }

    // Properties are only filled in for bound nodes.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
}
