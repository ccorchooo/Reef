import QtQuick
import qs.theme
import qs.services
import qs.components

// The Coral app's composer: a surface-container-high card with the waiting attachments
// (thumbnails or file chips, each with a remove button; reading ones dimmed, failed ones in
// error), the question (it grows to coral-composer-max, then scrolls; Enter asks,
// Shift+Enter starts a new line), and Attach, Speak (voice mode) and Send (Stop while Coral
// answers).
Rectangle {
    id: root

    signal attachRequested

    function focusField() {
        input.forceActiveFocus();
    }
    // Start the question for the user to finish.
    function prefill(text) {
        input.text = text;
        input.forceActiveFocus();
        input.cursorPosition = input.length;
    }
    function send() {
        if (Coral.busy) {
            Coral.stop();
            return;
        }
        if (!canSend)
            return;
        Coral.ask(input.text);
        input.text = "";
    }
    readonly property bool reading: Coral.pending.some(a => !a.ready && a.error === "")
    readonly property bool canSend: !reading && (input.text.trim() !== "" || Coral.pending.some(a => a.ready))

    implicitHeight: column.implicitHeight + Tokens.space3 * 2
    radius: Tokens.radiusXl
    color: Colors.surfaceContainerHigh
    border.width: input.activeFocus ? 2 : 0
    border.color: Colors.primary

    Column {
        id: column
        x: Tokens.space4
        y: Tokens.space3
        width: parent.width - Tokens.space4 * 2
        spacing: Tokens.space2

        Flow {
            width: parent.width
            visible: Coral.pending.length > 0
            spacing: Tokens.space2
            Repeater {
                model: Coral.pending
                Item {
                    id: att
                    required property var modelData
                    readonly property bool image: modelData.kind === "image"
                    width: image ? Tokens.coralAppThumb : chipRow.implicitWidth + Tokens.space3 * 2
                    height: image ? Tokens.coralAppThumb : Tokens.chipHeight
                    opacity: modelData.ready || modelData.error !== "" ? 1 : Tokens.disabledOpacity
                    Accessible.role: Accessible.StaticText
                    Accessible.name: modelData.name + (modelData.error ? ": " + modelData.error : modelData.ready ? "" : ", reading")

                    ShapeImage {
                        anchors.fill: parent
                        visible: att.image
                        shape: "squircle"
                        source: visible ? "file://" + att.modelData.path : ""
                        color: Colors.surfaceContainerHighest
                        icon: "image"
                        iconColor: Colors.on.surfaceVariant
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: !att.image
                        radius: height / 2
                        color: att.modelData.error ? Colors.errorContainer : Colors.surfaceContainerHighest
                        Row {
                            id: chipRow
                            anchors.verticalCenter: parent.verticalCenter
                            x: Tokens.space3
                            spacing: Tokens.space1
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: att.modelData.error ? "error" : "description"
                                size: Tokens.iconSm
                                color: att.modelData.error ? Colors.on.errorContainer : Colors.on.surfaceVariant
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, Tokens.coralMenuWidth)
                                elide: Text.ElideMiddle
                                style: "chipLabel"
                                color: att.modelData.error ? Colors.on.errorContainer : Colors.on.surface
                                text: att.modelData.error ? att.modelData.name + " · " + att.modelData.error : att.modelData.name
                            }
                            Item {
                                width: Tokens.coralAppTool - Tokens.space2
                                height: 1
                            }
                        }
                    }
                    CoralToolButton {
                        anchors.right: parent.right
                        anchors.top: att.image ? parent.top : undefined
                        anchors.verticalCenter: att.image ? undefined : parent.verticalCenter
                        size: Tokens.coralAppTool - Tokens.space2
                        iconSize: Tokens.iconXs
                        icon: "close"
                        label: "Remove " + att.modelData.name
                        fill: att.image ? Colors.surfaceContainerHighest : Qt.alpha(Colors.surfaceContainerHighest, 0)
                        color: Colors.on.surface
                        onClicked: Coral.unattach(att.modelData.id)
                    }
                }
            }
        }

        Flickable {
            id: scroller
            width: parent.width
            height: Math.min(input.implicitHeight, Tokens.coralComposerMax)
            contentHeight: input.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            function follow() {
                const r = input.cursorRectangle;
                if (r.y < contentY)
                    contentY = r.y;
                else if (r.y + r.height > contentY + height)
                    contentY = r.y + r.height - height;
            }

            TextEdit {
                id: input
                width: scroller.width
                wrapMode: TextEdit.Wrap
                font: Type.font("bodyLg")
                color: Colors.on.surface
                selectionColor: Colors.primaryContainer
                selectedTextColor: Colors.on.primaryContainer
                focus: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Ask Coral"
                onCursorRectangleChanged: scroller.follow()
                Keys.onPressed: event => {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                        root.send();
                        event.accepted = true;
                    }
                }

                StyledText {
                    visible: input.text === ""
                    style: "bodyLg"
                    color: Colors.on.surfaceVariant
                    text: Coral.messages.length > 0 ? "Ask a follow-up…" : "Ask Coral…"
                }
            }
        }

        Item {
            width: parent.width
            height: Tokens.coralButton

            CoralToolButton {
                anchors.verticalCenter: parent.verticalCenter
                size: Tokens.coralButton
                icon: "attach_file"
                label: "Attach files"
                onClicked: root.attachRequested()
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space1
                CoralToolButton {
                    visible: CoralVoice.available
                    size: Tokens.coralButton
                    icon: "mic"
                    label: "Speak"
                    onClicked: CoralVoice.start()
                }
                CoralToolButton {
                    size: Tokens.coralButton
                    radius: Tokens.radiusMd
                    icon: Coral.busy ? "stop" : "arrow_upward"
                    filled: true
                    label: Coral.busy ? "Stop" : "Send"
                    enabledState: Coral.busy || root.canSend
                    fill: Colors.primary
                    color: Colors.on.primary
                    onClicked: root.send()
                }
            }
        }
    }
}
