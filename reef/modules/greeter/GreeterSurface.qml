import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components
import qs.modules.island

// The login greeter on one monitor (SURFACES.md → Login greeter; screens/Greeter).
// The wallpaper under a light black scrim (greeter-scrim). Top left the logo lockup, top
// right the clock and date. In the center the user's avatar in a cookie, the name, the
// password field (shapes for characters, a primary ring), and the other users as small
// circles. Bottom left the session picker; bottom right accessibility (zoom), the
// keyboard layout and the power buttons. `form` is false on the other monitors, which
// show only the wallpaper and the clock.
//
// Entry: the avatar blooms in on spatial-bouncy, everything else fades in after it
// (effects-default). A wrong password shakes the field and rocks the avatar.
FocusScope {
    id: root

    property bool form: true
    readonly property string wallpaper: Config.options.look.wallpaper
    readonly property real zoomNext: ({ "1": 1.25, "1.25": 1.5 })[String(Config.options.scale.zoom)] ?? 1

    Spring {
        id: bloom
        spec: Motion.spatialBouncy
        target: 0
    }
    Spring {
        id: content
        spec: Motion.effectsDefault
        target: bloom.value > 0.7 ? 1 : 0
    }
    Spring {
        id: rock
        spec: Motion.spatialFast
        target: 0
    }
    Component.onCompleted: Qt.callLater(() => {
        bloom.target = 1;
        if (root.form)
            field.focusField();
    })

    Connections {
        target: Greeter
        function onFailed() {
            field.fail();
            rock.velocity = Tokens.shakeDistance * 40;
        }
    }

    // ── background ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
    }
    // With no wallpaper, the reference composition: a few large shapes in the surface
    // containers (the mockup's stand-in for a picture).
    Item {
        anchors.fill: parent
        visible: root.wallpaper === ""
        ShapeItem {
            x: parent.width * 0.55; y: -parent.height * 0.275
            width: parent.height * 0.9; height: width
            color: Colors.surfaceContainerHigh
        }
        ShapeItem {
            x: parent.width * 0.21; y: -parent.height * 0.24
            width: parent.height * 0.375; height: width
            color: Colors.surfaceContainer
        }
        ShapeItem {
            x: -parent.width * 0.11; y: parent.height * 0.475
            width: parent.height * 0.72; height: width
            radii: Shapes.sample("cookie9", width, height)
            color: Colors.surfaceContainerHighest
        }
        ShapeItem {
            x: parent.width * 0.64; y: parent.height * 0.65
            width: parent.height * 0.6; height: width
            radii: Shapes.sample("sunny", width, height)
            // A shade of the avatar's color, as dim as the scrim.
            color: Qt.alpha(Colors.tertiaryContainer, Tokens.greeterScrimOpacity)
        }
    }
    Image {
        anchors.fill: parent
        visible: root.wallpaper !== ""
        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
    }
    Rectangle {
        anchors.fill: parent
        color: Colors.island
        opacity: Tokens.greeterScrimOpacity
    }

    // ── top: lockup, clock ──────────────────────────────────────
    Row {
        x: Tokens.space8
        y: Tokens.space8
        spacing: Tokens.space3
        opacity: content.value
        Logo {
            anchors.verticalCenter: parent.verticalCenter
            size: Tokens.greeterLogo
            color: Colors.on.surface
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            style: "greeterWordmark"
            color: Colors.on.surface
            text: "Reef"
        }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space8
        y: Tokens.space8 + (Tokens.greeterLogo - height) / 2
        spacing: Tokens.space1
        opacity: content.value
        StyledText {
            style: "greeterClock"
            color: Colors.on.surface
            text: Time.time
        }
        StyledText {
            style: "greeterClock"
            color: Colors.on.surfaceVariant
            text: "· " + Qt.formatDate(Time.now, "ddd d MMM")
        }
    }

    // ── center: avatar, name, field, users ──────────────────────
    Column {
        visible: root.form
        anchors.centerIn: parent
        spacing: Tokens.space5

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Tokens.greeterAvatar
            height: Tokens.greeterAvatar
            scale: Math.max(0, bloom.value)
            rotation: rock.value

            ShapeImage {
                id: avatar
                anchors.fill: parent
                shape: "cookie9"
                color: Colors.tertiaryContainer
                source: Greeter.current ? "file://" + Greeter.current.avatar : ""
            }
            StyledText {
                anchors.centerIn: parent
                visible: !avatar.hasImage
                style: "avatarInitialLg"
                color: Colors.on.tertiaryContainer
                text: (Greeter.current?.display ?? "?").slice(0, 1).toUpperCase()
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            style: "greeterName"
            color: Colors.on.surface
            text: Greeter.current?.display ?? ""
            opacity: content.value
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.space2
            opacity: content.value

            PasswordField {
                id: field
                focus: true
                width: Tokens.greeterFieldWidth
                height: Tokens.greeterFieldHeight
                submitSize: Tokens.greeterSubmit
                ring: true
                submitLabel: "Log in"
                busy: Greeter.busy
                onSubmitted: text => Greeter.login(text)
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                width: Math.min(implicitWidth, Tokens.greeterFieldWidth)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                style: "bodySm"
                color: Colors.on.surfaceVariant
                text: Greeter.message
            }
        }

        // The other people on this computer (the current one is above).
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Greeter.users.length > 1
            spacing: Tokens.space2
            opacity: content.value
            Repeater {
                model: Greeter.users.filter(u => u.name !== Greeter.user)
                Rectangle {
                    required property var modelData
                    width: Tokens.greeterUser
                    height: Tokens.greeterUser
                    radius: width / 2
                    color: userMouse.containsMouse || activeFocus ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.display
                    Keys.onReturnPressed: Greeter.choose(modelData.name)
                    Keys.onSpacePressed: Greeter.choose(modelData.name)
                    StyledText {
                        anchors.centerIn: parent
                        style: "avatarInitial"
                        color: Colors.on.surfaceVariant
                        text: parent.modelData.display.slice(0, 1).toUpperCase()
                    }
                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Greeter.choose(parent.modelData.name);
                            field.clear();
                            field.focusField();
                        }
                    }
                }
            }
        }
    }

    // ── bottom left: session ────────────────────────────────────
    Item {
        id: sessionPicker
        visible: root.form
        x: Tokens.space8
        y: root.height - Tokens.space8 - Tokens.greeterPillHeight
        width: sessionPill.width
        height: Tokens.greeterPillHeight
        opacity: content.value
        property bool open: false

        Rectangle {
            id: sessionPill
            width: sessionRow.implicitWidth + Tokens.space4 * 2
            height: Tokens.greeterPillHeight
            radius: height / 2
            color: Colors.island
            activeFocusOnTab: true
            Accessible.role: Accessible.ComboBox
            Accessible.name: "Session: " + (Greeter.currentSession?.name ?? "")
            Keys.onReturnPressed: sessionPicker.open = !sessionPicker.open
            Keys.onSpacePressed: sessionPicker.open = !sessionPicker.open
            Keys.onEscapePressed: sessionPicker.open = false
            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: Tokens.space2
                Logo {
                    anchors.verticalCenter: parent.verticalCenter
                    size: Tokens.iconSm
                    color: Colors.on.island
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    style: "labelLg"
                    color: Colors.on.island
                    text: Greeter.currentSession?.name ?? "Session"
                }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: sessionPicker.open ? "expand_more" : "expand_less"
                    size: Tokens.iconSm
                    color: Colors.on.island
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionPicker.open = !sessionPicker.open
            }
        }

        // The sessions, above the pill.
        Rectangle {
            visible: sessionPicker.open
            y: -height - Tokens.space2
            width: Math.max(sessionPill.width, sessionList.implicitWidth + Tokens.space2 * 2)
            height: sessionList.implicitHeight + Tokens.space2 * 2
            radius: Tokens.radiusLg
            color: Colors.surfaceContainerHigh
            Column {
                id: sessionList
                anchors.centerIn: parent
                width: parent.width - Tokens.space2 * 2
                Repeater {
                    model: Greeter.sessions
                    Rectangle {
                        required property var modelData
                        width: sessionList.width
                        implicitWidth: sessionName.implicitWidth + Tokens.space4 * 2
                        height: Tokens.listRowHeight
                        radius: Tokens.radiusMd
                        color: modelData.id === Greeter.session ? Colors.secondaryContainer
                            : rowMouse.containsMouse ? Colors.surfaceContainerHighest : "transparent"
                        StyledText {
                            id: sessionName
                            anchors.verticalCenter: parent.verticalCenter
                            x: Tokens.space4
                            style: "bodyMd"
                            color: parent.modelData.id === Greeter.session ? Colors.on.secondaryContainer : Colors.on.surface
                            text: parent.modelData.name
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Greeter.chooseSession(parent.modelData.id);
                                sessionPicker.open = false;
                                field.focusField();
                            }
                        }
                    }
                }
            }
        }
    }

    // ── bottom right: accessibility, layout, power ──────────────
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space8
        y: root.height - Tokens.space8 - Tokens.greeterPillHeight
        spacing: Tokens.space2
        opacity: content.value

        Rectangle {
            width: a11yRow.implicitWidth + Tokens.space2 * 2
            height: Tokens.greeterPillHeight
            radius: height / 2
            color: Colors.island
            Row {
                id: a11yRow
                anchors.centerIn: parent
                spacing: Tokens.space1
                IslandButton {
                    width: Tokens.lockButton
                    height: Tokens.lockButton
                    icon: "accessibility_new"
                    label: "Zoom " + Math.round(root.zoomNext * 100) + "%"
                    iconSize: Tokens.iconMd
                    filled: false
                    color: Qt.alpha(Colors.islandContainerHigh, 0)
                    onClicked: Config.options.scale.zoom = root.zoomNext
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: Tokens.space2
                    visible: text !== ""
                    style: "keyboardLayout"
                    color: Colors.on.island
                    text: Keyboard.short
                    Accessible.name: "Keyboard layout " + Keyboard.layout
                }
            }
        }

        Rectangle {
            width: powerRow.implicitWidth + Tokens.space1 * 2
            height: Tokens.greeterPillHeight
            radius: height / 2
            color: Colors.island
            Row {
                id: powerRow
                anchors.centerIn: parent
                spacing: Tokens.spaceHalf
                Repeater {
                    model: [
                        { icon: "bedtime", label: "Sleep", cmd: ["systemctl", "suspend"] },
                        { icon: "restart_alt", label: "Restart", cmd: ["systemctl", "reboot"] },
                        { icon: "power_settings_new", label: "Power off", cmd: ["systemctl", "poweroff"] }
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
                        onClicked: Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}
