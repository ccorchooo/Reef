import QtQuick
import qs.theme

// A password field where each typed character appears as the next M3E shape
// (Shapes.passwordSequence; SURFACES.md → Lock screen). A black pill (`island`).
//
//   PasswordField { onSubmitted: text => Lock.submit(text) }
//
// New shapes pop up from below, spin in and bloom from a circle into their shape with
// spatial-bouncy, and the ones beside them hop in a small wave (typing or erasing); the
// newest is island-accent. fail() plays the
// wrong-password moment (MOTION.md): every shape morphs back to a circle, the row shakes
// ±shake-distance with spatial-fast and the field tints error-container for error-tint,
// then it clears. The text itself is never drawn. A focus scope: giving the field focus
// puts the keyboard in its text, never on the arrow button.
FocusScope {
    id: root

    // A primary ring while focused (dialogs, the greeter; the lock screen has none).
    property bool ring: false
    property bool showSubmit: true
    property real submitSize: Tokens.passwordSubmit
    property string label: "Password"
    property string submitLabel: "Unlock"
    // Checking: typing is held until the answer.
    property bool busy: false
    readonly property alias text: input.text
    readonly property bool failing: _failing
    signal submitted(string text)

    implicitWidth: Tokens.passwordFieldWidth
    implicitHeight: Tokens.passwordFieldHeight

    function clear() {
        input.text = "";
    }
    function focusField() {
        input.forceActiveFocus();
    }
    function submit() {
        if (input.text === "" || busy || _failing)
            return;
        submitted(input.text);
    }
    function fail() {
        _failing = true;
        shake.kick(Tokens.shakeDistance);
        errorTint.restart();
    }

    property bool _failing: false
    // A character was typed (at = its index) or erased (at = the new length).
    signal rippled(int at)
    property int _length: 0

    Timer {
        id: errorTint
        interval: Tokens.errorTint
        onTriggered: {
            root._failing = false;
            input.text = "";
        }
    }

    ColorSpring {
        id: fill
        spec: Motion.effectsDefault
        target: root._failing ? Colors.errorContainer : Colors.island
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: fill.value
        border.width: root.ring && input.activeFocus ? 2 : 0
        border.color: Colors.primary
    }

    // The shapes. Long passwords scroll so the newest stays in view.
    Item {
        id: area
        anchors.left: parent.left
        anchors.right: submit.visible ? submit.left : parent.right
        anchors.leftMargin: Tokens.passwordFieldPadding
        anchors.rightMargin: submit.visible ? Tokens.space2_5 : Tokens.passwordFieldPadding
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        // The field's full height, so hops and bounces aren't cut off.
        clip: true

        Spring {
            id: shake
            spec: Motion.spatialFast
            target: 0
        }

        Row {
            x: Math.min(0, area.width - width) + shake.value
            y: (area.height - Tokens.passwordShape) / 2
            spacing: Tokens.space2

            Repeater {
                model: input.text.length

                Item {
                    id: glyph
                    required property int index
                    readonly property bool newest: index === input.text.length - 1
                    width: Tokens.passwordShape
                    height: Tokens.passwordShape

                    // Arrives alive: pops up from below, spins into place and blooms from a
                    // circle into its shape, all on spatial-bouncy.
                    Spring {
                        id: pop
                        spec: Motion.spatialBouncy
                    }
                    Spring {
                        id: rise
                        spec: Motion.spatialBouncy
                        target: 0
                    }
                    Spring {
                        id: spin
                        spec: Motion.spatialBouncy
                        target: 0
                    }
                    property bool bloomed: false
                    Component.onCompleted: {
                        rise.snap(Tokens.passwordShape);
                        spin.snap(Tokens.passwordSpin);
                        // After the springs are ready, so the changes animate.
                        Qt.callLater(() => {
                            pop.target = 1;
                            rise.target = 0;
                            spin.target = 0;
                            glyph.bloomed = true;
                        });
                    }

                    // A shape typed or erased nearby: hop, less the further away, in a wave.
                    Timer {
                        id: ripple
                        property int distance: 1
                        onTriggered: rise.kick(-Tokens.passwordHop / distance)
                    }
                    Connections {
                        target: root
                        function onRippled(at) {
                            const d = at - glyph.index;
                            if (d < 1 || d > Tokens.staggerMax)
                                return;
                            ripple.distance = d;
                            ripple.interval = Math.max(1, Motion.stagger(d));
                            ripple.restart();
                        }
                    }

                    ColorSpring {
                        id: tone
                        spec: Motion.effectsDefault
                        target: glyph.newest && !root._failing ? Colors.islandAccent : Colors.on.island
                    }

                    ShapeMorph {
                        anchors.fill: parent
                        scale: Math.max(0, pop.value)
                        rotation: spin.value
                        transform: Translate {
                            y: rise.value
                        }
                        spec: Motion.spatialBouncy
                        shape: root._failing || !glyph.bloomed ? "circle" : Shapes.passwordSequence[glyph.index % Shapes.passwordSequence.length]
                        color: tone.value
                    }
                }
            }
        }
    }

    // Takes the typing; invisible (the shapes are the only trace of the text).
    TextInput {
        id: input
        anchors.fill: area
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        readOnly: root.busy || root._failing
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        onTextChanged: {
            const n = text.length;
            if (n > root._length)
                root.rippled(n - 1);
            else if (n < root._length && n > 0)
                root.rippled(n);
            root._length = n;
        }
        Accessible.role: Accessible.EditableText
        Accessible.name: root.label
        Accessible.passwordEdit: true
        Keys.onReturnPressed: root.submit()
        Keys.onEnterPressed: root.submit()
        Keys.onEscapePressed: event => {
            event.accepted = input.text !== "";
            input.text = "";
        }
    }

    MouseArea {
        anchors.fill: area
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }

    Item {
        id: submit
        visible: root.showSubmit
        width: root.submitSize
        height: root.submitSize
        anchors.right: parent.right
        anchors.rightMargin: (root.height - height) / 2
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.busy ? Tokens.disabledOpacity : 1

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.submitLabel
        Keys.onReturnPressed: root.submit()
        Keys.onSpacePressed: root.submit()

        Spring {
            id: corner
            spec: Motion.spatialFast
            target: submitMouse.pressed ? Tokens.radiusSm : Tokens.radiusMd
        }

        Rectangle {
            anchors.fill: parent
            radius: corner.value
            color: Colors.primary
            border.width: submit.activeFocus ? 2 : 0
            border.color: Colors.on.primary
        }
        Icon {
            anchors.centerIn: parent
            name: "arrow_forward"
            size: Tokens.iconMd
            color: Colors.on.primary
        }
        MouseArea {
            id: submitMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.submit()
        }
    }
}
