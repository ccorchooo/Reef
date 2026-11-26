import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components
import qs.modules.island

// Coral's voice mode on one monitor (screens/CoralVoice; SURFACES.md → Coral → Voice).
//
// The Island leaves the top center as the pill and grows into the Pearl (spatial-bouncy),
// the Island hiding meanwhile. The Pearl pulses: layered island-accent outlines grow with
// the voice's loudness (listening: yours, speaking: Coral's), turn and morph between cookie
// shapes on the beat, and glow at the peaks. Under it: "Coral · listening" (or writing it
// down / thinking / speaking), the transcript in quotes, and Type instead and Stop.
// When it's over the Pearl folds back into the Island, which opens on the conversation.
// Escape cancels; Stop while listening uses what was said so far.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    readonly property bool mine: CoralVoice.active && CoralVoice.screen === (modelData?.name ?? "")
    readonly property real spread: Tokens.pearlSize * Tokens.coralPulse

    anchors.top: true
    implicitWidth: Math.max(Tokens.coralTranscriptWidth, Tokens.pearlSize + spread * 2) + Tokens.space8 * 2
    implicitHeight: words.y + words.implicitHeight + Tokens.space8
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: mine || form.running || form.value > 0.001
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-coral"
    WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Only the words and buttons take the pointer.
    mask: Region {
        item: words
    }

    // ── the Island becoming the Pearl ───────────────────────────
    property var from: ({ x: 0, y: 0, w: 0, h: 0 })
    Spring {
        id: form
        spec: root.mine ? Motion.spatialBouncy : Motion.spatialDefault
        target: 0
    }
    Spring {
        id: content
        spec: Motion.effectsDefault
        target: root.mine && form.value > 0.75 ? 1 : 0
    }
    onMineChanged: {
        if (mine) {
            const r = IslandState.bodyRect((modelData?.name ?? ""), (modelData?.width ?? 0));
            from = { x: r.x - ((modelData?.width ?? 0) - width) / 2, y: r.y, w: r.w, h: r.h };
            IslandState.pearlScreen = (modelData?.name ?? "");
            form.target = 1;
            focusTimer.restart();
        } else {
            form.target = 0;
        }
    }
    // Back in the Island: it shows again (and opens on the chat, see CoralVoice._finish).
    readonly property bool out: mine || form.running || form.value > 0.001
    onOutChanged: {
        if (!out && IslandState.pearlScreen === (modelData?.name ?? ""))
            IslandState.pearlScreen = "";
    }
    Timer {
        id: focusTimer
        interval: 1
        onTriggered: keys.forceActiveFocus()
    }
    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: CoralVoice.cancel()
    }

    // ── the pulse ───────────────────────────────────────────────
    // Loudness, with a kick on each beat while Coral writes or thinks.
    Spring {
        id: pulse
        spec: Motion.spatialFast
        target: CoralVoice.level
    }
    Spring {
        id: spin
        spec: Motion.spatialBouncy
        target: 0
    }
    property int beat: 0
    readonly property var ringShapes: ["cookie9", "sunny", "flower", "cookie12", "clover8", "cookie6"]
    Timer {
        interval: Tokens.coralBeat / Motion.speed
        repeat: true
        running: root.mine && !Motion.reduceMotion
        onTriggered: {
            spin.target += Tokens.coralBeatAngle;
            root.beat++;
            if (CoralVoice.phase === "transcribing" || CoralVoice.phase === "thinking")
                pulse.kick(Tokens.coralPulse);
        }
    }

    Item {
        id: pearl
        readonly property real t: form.value
        readonly property real placeX: (root.width - Tokens.pearlSize) / 2
        x: root.from.x + (placeX - root.from.x) * t
        y: root.from.y + (Tokens.space2 + root.spread - root.from.y) * t
        width: root.from.w + (Tokens.pearlSize - root.from.w) * t
        height: root.from.h + (Tokens.pearlSize - root.from.h) * t

        // Outlines, the outermost growing furthest.
        Repeater {
            model: 3
            ShapeMorph {
                required property int index
                readonly property real grow: 1 + Tokens.coralPulse * (index + 1) / 3 * Math.max(0, pulse.value)
                anchors.centerIn: parent
                width: Tokens.pearlSize * grow
                height: width
                opacity: content.value
                visible: opacity > 0.01
                spec: Motion.spatialBouncy
                shape: root.ringShapes[(root.beat + index * 2) % root.ringShapes.length]
                color: "transparent"
                strokeWidth: Tokens.coralOutline
                strokeColor: Qt.alpha(Colors.islandAccent, Tokens.coralOutlineOpacity + (1 - Tokens.coralOutlineOpacity) * Math.min(1, Math.max(0, pulse.value)))
                rotation: (index % 2 ? -1 : 1) * spin.value / (index + 1)
            }
        }

        ShapeMorph {
            anchors.fill: parent
            shape: form.target === 1 ? "cookie9" : "pill"
            spec: form.spec
            color: Colors.island
        }

        // Coral's mark at the center.
        Rectangle {
            anchors.centerIn: parent
            width: Tokens.coralOrbCore
            height: width
            radius: width / 2
            color: Colors.islandContainerHigh
            opacity: content.value
            ShapeItem {
                anchors.centerIn: parent
                width: Tokens.coralOrbMark * (1 + Math.max(0, pulse.value) * Tokens.coralPulse)
                height: width
                radii: Shapes.sample("cookie6", width, height)
                color: Colors.islandAccent
                rotation: spin.value
            }
        }
    }

    // ── words and buttons ───────────────────────────────────────
    Column {
        id: words
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.space2 + root.spread * 2 + Tokens.pearlSize + Tokens.space4
        spacing: Tokens.space3
        opacity: content.value
        visible: opacity > 0.01

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: phaseLabel.implicitWidth + Tokens.cayPadding * 2
            height: Tokens.chipHeight
            radius: height / 2
            color: Colors.island
            StyledText {
                id: phaseLabel
                anchors.centerIn: parent
                style: "labelMd"
                font.capitalization: Font.AllUppercase
                color: Colors.islandAccent
                text: "Coral · " + ({ listening: "listening", transcribing: "writing it down", thinking: "thinking", speaking: "speaking" })[CoralVoice.phase] ?? ""
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: CoralVoice.transcript !== ""
            width: transcriptText.width + Tokens.space5 * 2
            height: transcriptText.implicitHeight + Tokens.space3 * 2
            radius: Math.min(height / 2, Tokens.radiusXl)
            color: Colors.island
            StyledText {
                id: transcriptText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, Tokens.coralTranscriptWidth - Tokens.space5 * 2)
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                style: "bodyLg"
                color: Colors.on.island
                text: "“" + CoralVoice.transcript + "”"
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.space2
            IslandTextButton {
                icon: "keyboard"
                text: "Type instead"
                color: Colors.island
                onClicked: CoralVoice.typeInstead()
            }
            IslandTextButton {
                icon: "stop"
                text: "Stop"
                color: Colors.errorContainer
                contentColor: Colors.on.errorContainer
                onClicked: CoralVoice.phase === "listening" ? CoralVoice.done() : CoralVoice.cancel()
            }
        }
    }
}
