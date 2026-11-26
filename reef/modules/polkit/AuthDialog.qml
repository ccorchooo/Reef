import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// Polkit authentication dialog (SURFACES.md → Authentication dialog; screens/AuthDialog).
// A centered radius-xl card over a scrim on the monitor that had focus: a lock in a
// cookie, "Authentication required", the request's message, the user chip, a password
// field with shapes, Details (the polkit action), Cancel and Authenticate.
// A wrong password shakes the field (MOTION.md → Wrong password). Escape cancels.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    readonly property var flow: Polkit.flow
    readonly property bool open: Polkit.active
        && (Monitors.has(Polkit.screenName) ? Polkit.screenName : Monitors.focused) === (modelData?.name ?? "")

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-polkit"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Mapped while open and while it fades away.
    visible: open || scrimFade.value > 0.01

    property bool detailsOpen: false

    onOpenChanged: {
        if (!open)
            return;
        detailsOpen = false;
        field.clear();
        focusField.restart();
    }
    // Give the surface a moment to receive keyboard focus.
    Timer {
        id: focusField
        interval: 1
        onTriggered: field.focusField()
    }

    function authenticate() {
        if (root.flow?.isResponseRequired && field.text !== "")
            root.flow.submit(field.text);
    }
    function cancel() {
        root.flow?.cancelAuthenticationRequest();
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() {
            field.fail();
        }
    }

    Spring {
        id: scrimFade
        spec: Motion.effectsSlow
        target: root.open ? 1 : 0
    }
    Spring {
        id: rise
        spec: Motion.spatialDefault
        target: root.open ? 1 : 0
    }
    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.open ? 1 : 0
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: scrimFade.value
    }
    // Modal: clicks outside the card go nowhere.
    MouseArea {
        anchors.fill: parent
        enabled: root.open
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.cancel()
    }

    Item {
        id: dialog
        width: Tokens.dialogWidth
        height: column.implicitHeight + Tokens.space6 * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.height - height) / 2 + (1 - rise.value) * Tokens.space6
        opacity: fade.value

        Accessible.role: Accessible.Dialog
        Accessible.name: "Authentication required"

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            offset.x: Colors.shadowDialog.x
            offset.y: Colors.shadowDialog.y
            blur: Colors.shadowDialog.blur
            color: Colors.shadowDialog.color
        }
        Rectangle {
            id: card
            anchors.fill: parent
            radius: Tokens.radiusXl
            color: Colors.surfaceContainerLow
        }

        Column {
            id: column
            x: Tokens.space6
            y: Tokens.space6
            width: parent.width - Tokens.space6 * 2
            spacing: Tokens.space3_5

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Tokens.dialogIcon
                height: Tokens.dialogIcon
                ShapeItem {
                    anchors.fill: parent
                    radii: Shapes.sample("cookie4", width, height)
                    color: Colors.primaryContainer
                }
                Icon {
                    anchors.centerIn: parent
                    name: "lock"
                    size: Tokens.dialogIconGlyph
                    filled: true
                    color: Colors.on.primaryContainer
                }
            }

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                style: "dialogTitle"
                text: "Authentication required"
            }

            StyledText {
                width: parent.width
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                lineHeightMode: Text.ProportionalHeight
                lineHeight: 1
                style: "bodyMd"
                color: Colors.on.surfaceVariant
                text: root.flow?.message ?? ""
            }

            // The user (several identities: click to switch).
            Rectangle {
                id: userChip
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property var identities: root.flow?.identities ?? []
                readonly property string name: root.flow?.selectedIdentity?.displayName || Quickshell.env("USER") || ""
                width: userRow.implicitWidth + Tokens.space1 + Tokens.space4
                height: Tokens.userChipHeight
                radius: height / 2
                color: Colors.surfaceContainerHigh

                activeFocusOnTab: identities.length > 1
                Accessible.role: identities.length > 1 ? Accessible.Button : Accessible.StaticText
                Accessible.name: "Authenticating as " + name
                Keys.onReturnPressed: next()
                Keys.onSpacePressed: next()
                border.width: activeFocus ? 2 : 0
                border.color: Colors.primary

                function next() {
                    const ids = identities;
                    if (ids.length < 2)
                        return;
                    const i = ids.indexOf(root.flow.selectedIdentity);
                    root.flow.selectedIdentity = ids[(i + 1) % ids.length];
                }

                Row {
                    id: userRow
                    x: Tokens.space1
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space2_5

                    Rectangle {
                        width: Tokens.avatarSm
                        height: Tokens.avatarSm
                        radius: width / 2
                        color: Colors.tertiaryContainer
                        StyledText {
                            anchors.centerIn: parent
                            style: "avatarInitialSm"
                            color: Colors.on.tertiaryContainer
                            text: userChip.name.charAt(0).toUpperCase()
                        }
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        style: "tileLabel"
                        text: userChip.name
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: userChip.identities.length > 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userChip.next()
                }
            }

            PasswordField {
                id: field
                focus: true
                width: parent.width
                ring: true
                showSubmit: false
                label: root.flow?.inputPrompt || "Password"
                busy: !(root.flow?.isResponseRequired ?? false)
                onSubmitted: root.authenticate()
            }

            // Details: the polkit action being asked for.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: detailsRow.implicitWidth + Tokens.space2 * 2
                height: Tokens.linkHeight

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: root.detailsOpen ? "Hide details" : "Details"
                Keys.onReturnPressed: root.detailsOpen = !root.detailsOpen
                Keys.onSpacePressed: root.detailsOpen = !root.detailsOpen

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                    border.color: Colors.primary
                }
                Row {
                    id: detailsRow
                    anchors.centerIn: parent
                    spacing: Tokens.space1
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        style: "chipLabel"
                        color: Colors.primary
                        text: "Details"
                    }
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.detailsOpen ? "expand_less" : "expand_more"
                        size: Tokens.iconXs
                        color: Colors.primary
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.detailsOpen = !root.detailsOpen
                }
            }

            StyledText {
                width: parent.width
                visible: root.detailsOpen
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAnywhere
                style: "monoSm"
                color: Colors.on.surfaceVariant
                text: root.flow?.actionId ?? ""
            }

            Row {
                width: parent.width
                spacing: Tokens.space2

                PillButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Cancel"
                    onClicked: root.cancel()
                }
                PillButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Authenticate"
                    accent: true
                    enabledState: field.text !== "" && !field.busy
                    onClicked: root.authenticate()
                }
            }
        }
    }
}
