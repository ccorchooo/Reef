import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules.island

// The lock screen on one monitor (SURFACES.md → Lock screen; screens/Lock, parts/Pearl-Lock).
// Hosted by a WlSessionLockSurface, or by an overlay for the preview.
//
// The wallpaper, the Pearl with the clock and date, a greeting and a media chip. Bottom
// left: the password field (each character a shape) and a black cay with Sleep, Power
// off and Restart. Bottom right: network, battery and keyboard layout.
//
// Entry (MOTION.md → Island → Pearl): the Pearl starts as the resting Island at the top
// center, widens and rounds into the 9-lobed cookie as it grows to pearl-lock-size and
// settles with spatial-slow. One hero: everything else only fades in after it. A correct
// password folds it back toward the Island while the rest fades, then the lock lifts.
FocusScope {
    id: root

    readonly property bool leaving: Lock.unlocking
    readonly property string wallpaper: Config.options.look.wallpaper

    // 0 = the resting Island, 1 = the Pearl in place.
    Spring {
        id: form
        spec: root.leaving ? Motion.spatialDefault : Motion.spatialSlow
        target: 0
    }
    // Everything but the Pearl, and the Pearl's own clock.
    Spring {
        id: content
        spec: Motion.effectsDefault
        target: form.target === 1 && form.value > 0.75 ? 1 : 0
    }

    Component.onCompleted: Qt.callLater(() => {
        form.target = 1;
        field.focusField();
    })
    onLeavingChanged: {
        if (leaving)
            form.target = 0;
    }

    Connections {
        target: Lock
        function onFailed() {
            field.fail();
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

    Logo {
        x: Tokens.space8
        y: Tokens.space8 - (Tokens.lockLogo - Tokens.iconMd) / 2
        size: Tokens.lockLogo
        color: Colors.on.surface
        opacity: content.value
    }

    // ── the Pearl, greeting and media ───────────────────────────
    // Centered in the space above the bottom row.
    readonly property real bottomRow: Tokens.space8 + Tokens.passwordFieldHeight + Tokens.space8
    readonly property bool showChip: Config.options.lock.media && Media.active
    readonly property real columnHeight: Tokens.pearlLockSize
        + (Config.options.lock.greeting ? Tokens.space8 + greeting.height : 0)
        + (showChip ? Tokens.space2_5 + chip.height : 0)
    readonly property real columnTop: (height - bottomRow - columnHeight) / 2

    Item {
        id: pearl

        readonly property real t: form.value
        readonly property real restX: (root.width - Tokens.islandCollapsedWidth) / 2
        readonly property real placeX: (root.width - Tokens.pearlLockSize) / 2

        x: restX + (placeX - restX) * t
        y: Tokens.space2 + (root.columnTop - Tokens.space2) * t
        width: Tokens.islandCollapsedWidth + (Tokens.pearlLockSize - Tokens.islandCollapsedWidth) * t
        height: Tokens.islandCollapsedHeight + (Tokens.pearlLockSize - Tokens.islandCollapsedHeight) * t

        ShapeMorph {
            anchors.fill: parent
            shape: form.target === 1 ? "cookie9" : "pill"
            spec: form.spec
            color: Colors.island
        }

        Column {
            anchors.centerIn: parent
            spacing: Tokens.space1
            opacity: content.value

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "pearlClock"
                rond: 100
                text: Time.time
                color: Colors.on.island
                font.features: ({ tnum: 1 })
                Accessible.name: "Time " + Time.time
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "pearlDate"
                text: Qt.formatDate(Time.now, "dddd, d MMMM")
                color: Colors.on.islandVariant
            }
        }
    }

    StyledText {
        id: greeting
        visible: Config.options.lock.greeting
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.columnTop + Tokens.pearlLockSize + Tokens.space8
        style: "displaySm"
        color: Colors.on.surface
        opacity: content.value
        text: {
            const h = Time.now.getHours();
            return h >= 5 && h < 12 ? "Good morning" : h >= 12 && h < 17 ? "Good afternoon" : h >= 17 && h < 22 ? "Good evening" : "Good night";
        }
    }

    Rectangle {
        id: chip
        visible: root.showChip
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.columnTop + Tokens.pearlLockSize + (greeting.visible ? Tokens.space8 + greeting.height : 0) + Tokens.space2_5
        width: chipRow.implicitWidth + Tokens.cayPadding * 2
        height: Tokens.lockChipHeight
        radius: height / 2
        color: Qt.alpha(Colors.island, Tokens.lockChipOpacity)
        opacity: content.value

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Tokens.space2

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "music_note"
                size: Tokens.iconXs
                filled: true
                color: Colors.islandAccent
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.width / 3)
                elide: Text.ElideRight
                style: "bodySm"
                color: Colors.on.island
                text: Media.artist !== "" ? `${Media.title} · ${Media.artist}` : Media.title
            }
            Item {
                id: playPause
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.iconXs
                height: Tokens.iconXs
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: Media.playing ? "Pause" : "Play"
                Keys.onReturnPressed: Media.togglePlaying()
                Keys.onSpacePressed: Media.togglePlaying()

                Icon {
                    anchors.centerIn: parent
                    name: Media.playing ? "pause" : "play_arrow"
                    size: Tokens.iconXs
                    filled: true
                    color: Colors.on.island
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Tokens.spaceHalf
                    radius: width / 2
                    color: "transparent"
                    border.width: playPause.activeFocus ? 2 : 0
                    border.color: Colors.islandAccent
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Tokens.space1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.togglePlaying()
                }
            }
        }
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
