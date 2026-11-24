import QtQuick
import qs.theme

// One kind of live activity the Island can show. IslandState lists them in
// priority order; the collapsed pill, the secondary pill, the hover peek and the
// Now tab all draw from these properties.
QtObject {
    id: root

    property string key: ""
    property bool live: false
    // A short notice (charging, headphones connected) that ends by itself.
    property bool notice: false
    // Settings → Bar & Island → Activities can turn each one off.
    property bool enabled: true

    // ── collapsed pill ──
    property real width: Tokens.islandActivityWidth
    property string leading: "icon"        // "icon" | "dot" | "art"
    property string icon: ""
    property color iconColor: Colors.islandAccent
    property color dotColor: Colors.error
    property string trailing: "text"       // "text" | "waveform"
    property string text: ""
    property bool textMono: true
    property color textColor: Colors.islandAccent

    // ── peek and Now row ──
    property string title: ""
    property string subtitle: ""
    property bool subtitleMono: false
    property string value: ""              // big readout in the Now row
    // [{ icon, label, run, tone }] — tone: "accent" | "error" | "neutral". The peek shows the first.
    property var actions: []

    // A name for screen readers.
    readonly property string spoken: title + (subtitle ? ", " + subtitle : "")
}
