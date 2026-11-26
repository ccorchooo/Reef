import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.island

// The lock screen on one monitor (SURFACES.md → Lock screen; screens/Lock, parts/Pearl-Lock).
// Hosted by a WlSessionLockSurface, or by an overlay for the preview.
//
// The wallpaper and the Pearl (its face, or the Island's main activity: media is a small
// player). Bottom left: the password field (each character a shape) and a black cay with
// Sleep, Power off and Restart. Bottom right: network, battery and keyboard layout.
//
// Entry (MOTION.md → Island → Pearl): the Pearl starts as the resting Island at the top
// center, drops and rounds into its shape as it grows to pearl-lock-size on
// spatial-bouncy, stretching as it falls and squashing as it lands. One hero: everything
// else only fades in after it. Typing makes it swell, a wrong password rocks it. A correct
// password folds it back toward the Island while the rest fades, then the lock lifts.
FocusScope {
    id: root

    // The monitor it covers: its Island is where the Pearl comes from and goes back to.
    property string screenName: ""
    readonly property bool leaving: Lock.unlocking
    // Locked from the power actions: the Pearl already out there carries on from where it
    // is instead of dropping from the Island. Read once, when the lock appears.
    property var handoff: null
    readonly property bool fromPearl: handoff !== null && !leaving
    readonly property string wallpaper: Config.options.look.wallpaper

    // 0 = the resting Island, 1 = the Pearl in place. It drops in on spatial-bouncy,
    // overshoots and bounces back; leaving folds it up with spatial-default.
    Spring {
        id: form
        spec: root.leaving ? Motion.spatialDefault : Motion.spatialBouncy
        target: 0
    }
    // Everything but the Pearl, and the Pearl's own clock.
    Spring {
        id: content
        spec: Motion.effectsDefault
        target: form.target === 1 && form.value > 0.75 ? 1 : 0
    }

    Component.onCompleted: {
        if (Lock.handoff && Lock.handoff.screen === screenName)
            handoff = Lock.handoff;
        Qt.callLater(enter);
    }
    function enter() {
        form.target = 1;
        field.focusField();
    }
    onLeavingChanged: {
        if (leaving)
            form.target = 0;
    }

    Connections {
        target: Lock
        function onFailed() {
            field.fail();
            pearl.wobble();
        }
    }

    // The preview closes with Escape (the field takes the first one to clear itself).
    Keys.onEscapePressed: {
        if (Lock.preview)
            Lock.showPreview(false);
    }

    // ── background ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
    }
    Image {
        anchors.fill: parent
        visible: root.wallpaper !== ""
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
    }

    HomeLogo {
        x: Tokens.space8
        y: Tokens.space8 - (Tokens.lockLogo - Tokens.iconMd) / 2
        size: Tokens.lockLogo
        color: Colors.on.surface
        opacity: content.value
    }

    // ── the Pearl ───────────────────────────────────────────────
    // Centered in the space above the bottom row.
    readonly property real bottomRow: Tokens.space8 + Tokens.passwordFieldHeight + Tokens.space8
    readonly property real columnTop: (height - bottomRow - Tokens.pearlLockSize) / 2

    Pearl {
        id: pearl

        readonly property real t: form.value
        // Where it starts: the handed-over Pearl, else this monitor's Island (and where
        // it folds back to on unlock).
        readonly property var from: root.fromPearl ? root.handoff : IslandState.bodyRect(root.screenName, root.width)
        readonly property real placeX: (root.width - Tokens.pearlLockSize) / 2
        readonly property real fall: root.columnTop - from.y

        x: from.x + (placeX - from.x) * t
        y: from.y + fall * t
        width: from.w + (Tokens.pearlLockSize - from.w) * t
        height: from.h + (Tokens.pearlLockSize - from.h) * t

        activity: Config.options.lock.activity
        // A handed-over Pearl keeps its shape and content; leaving folds into the pill.
        resting: form.target !== 1 && !root.fromPearl
        spec: form.spec
        contentOpacity: root.fromPearl ? 1 : content.value
        // The drop stretches it; the bounce at the bottom squashes it.
        travel: form.velocity * fall
    }

    // ── bottom left: password and power ─────────────────────────
    Row {
        x: Tokens.space8
        y: root.height - Tokens.space8 - height
        spacing: Tokens.space2
        opacity: content.value

        PasswordField {
            id: field
            focus: true
            busy: Lock.busy || Lock.unlocking
            onSubmitted: text => Lock.submit(text)
            // The Pearl swells a little with each character.
            onTextChanged: if (text !== "") pearl.pulse()
        }

        Rectangle {
            visible: Config.options.lock.powerButtons
            width: powerRow.implicitWidth + Tokens.cayPaddingTight * 2
            height: Tokens.passwordFieldHeight
            radius: height / 2
            color: Colors.island

            Row {
                id: powerRow
                anchors.centerIn: parent
                spacing: Tokens.spaceHalf

                Repeater {
                    model: [
                        { icon: "bedtime", label: "Sleep", run: () => Session.suspend() },
                        { icon: "power_settings_new", label: "Power off", run: () => Session.poweroff() },
                        { icon: "restart_alt", label: "Restart", run: () => Session.reboot() }
                    ]
                    IslandButton {
                        required property var modelData
                        width: Tokens.lockButton
                        height: Tokens.lockButton
                        icon: modelData.icon
                        label: modelData.label
                        iconSize: Tokens.iconMd
                        filled: false
                        color: Qt.alpha(Colors.islandContainerHigh, 0)
                        // The preview only shows the lock screen: its power buttons do nothing.
                        onClicked: Lock.locked ? modelData.run() : console.info("Lock preview:", modelData.label, "(not run)")
                    }
                }
            }
        }
    }

    // ── bottom right: network, battery, keyboard layout ─────────
    Row {
        visible: Config.options.lock.status
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space8
        y: root.height - Tokens.space8 - (Tokens.passwordFieldHeight + height) / 2
        spacing: Tokens.space3
        opacity: content.value

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Network.icon
            size: Tokens.iconSm
            Accessible.ignored: false
            Accessible.name: Network.label
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.present
            name: Battery.icon
            size: Tokens.iconSm
            Accessible.ignored: false
            Accessible.name: Battery.label
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            style: "keyboardLayout"
            color: Colors.on.surfaceVariant
            text: Keyboard.short
            Accessible.name: "Keyboard layout " + Keyboard.layout
        }
    }
}
