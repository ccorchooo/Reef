import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// One message in the Coral app's conversation.
//   A question: on the right in a surface-container-high bubble (the corner by the edge
//   coral-bubble-tail), its images as squircle thumbnails and its files as chips above it.
//   Hovering shows Copy and Edit; Edit swaps the bubble for a field (Enter asks again from
//   there, Escape leaves it).
//   A reply: on the surface, Markdown (selectable), with what the model thought folded
//   above it, the actions Coral offers, and on hover Copy, Regenerate (the last reply) and
//   the model it came from. Errors read in `error`.
Item {
    id: root

    required property int index
    readonly property var msg: Coral.messages[index] ?? ({})
    readonly property bool mine: msg.role === "user"
    readonly property bool last: index === Coral.messages.length - 1
    readonly property bool streaming: last && !mine && Coral.busy
    property bool editing: false
    property bool showThought: false

    implicitHeight: column.implicitHeight + Tokens.space2

    HoverHandler {
        id: hover
    }

    Column {
        id: column
        width: parent.width
        spacing: Tokens.space2

        // ── attachments (questions) ──
        Flow {
            width: parent.width
            visible: root.mine && (root.msg.files ?? []).length > 0
            layoutDirection: Qt.RightToLeft
            spacing: Tokens.space2
            Repeater {
                model: root.mine ? root.msg.files ?? [] : []
                AttachmentChip {
                    required property var modelData
                    file: modelData
                }
            }
        }

        // ── the question ──
        Item {
            width: parent.width
            height: root.editing ? editBox.height : bubble.height
            visible: root.mine && ((root.msg.text ?? "") !== "" || root.editing)

            Rectangle {
                id: bubble
                visible: !root.editing
                anchors.right: parent.right
                width: Math.min(parent.width, Tokens.coralAppBubbleWidth, question.implicitWidth + Tokens.space4 * 2)
                height: question.implicitHeight + Tokens.space3 * 2
                color: Colors.surfaceContainerHigh
                topLeftRadius: Tokens.coralBubbleRadius
                topRightRadius: Tokens.coralBubbleRadius
                bottomLeftRadius: Tokens.coralBubbleRadius
                bottomRightRadius: Tokens.coralBubbleTail

                TextEdit {
                    id: question
                    x: Tokens.space4
                    y: Tokens.space3
                    width: Math.min(implicitWidth, Math.min(root.width, Tokens.coralAppBubbleWidth) - Tokens.space4 * 2)
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    font: Type.font("bodyLg")
                    color: Colors.on.surface
                    selectionColor: Colors.primaryContainer
                    selectedTextColor: Colors.on.primaryContainer
                    text: root.mine ? root.msg.text ?? "" : ""
                }
            }

            Rectangle {
                id: editBox
                visible: root.editing
                width: parent.width
                height: editor.implicitHeight + Tokens.space3 * 2 + editButtons.height + Tokens.space2
                radius: Tokens.radiusLg
                color: Colors.surfaceContainerHigh
                border.width: 2
                border.color: Colors.primary

                TextEdit {
                    id: editor
                    x: Tokens.space4
                    y: Tokens.space3
                    width: parent.width - Tokens.space4 * 2
                    wrapMode: TextEdit.Wrap
                    font: Type.font("bodyLg")
                    color: Colors.on.surface
                    selectionColor: Colors.primaryContainer
                    selectedTextColor: Colors.on.primaryContainer
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Edit the question"
                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                            root.save();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.editing = false;
                            event.accepted = true;
                        }
                    }
                }
                Row {
                    id: editButtons
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.space3
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Tokens.space3
                    spacing: Tokens.space2
                    PillButton {
                        text: "Cancel"
                        onClicked: root.editing = false
                    }
                    PillButton {
                        accent: true
                        text: "Ask"
                        onClicked: root.save()
                    }
                }
            }
        }

        // ── the reply ──
        // What the model thought, folded.
        Item {
            width: thoughtRow.implicitWidth
            height: thoughtRow.implicitHeight
            visible: !root.mine && (root.msg.reasoning ?? "") !== ""
            activeFocusOnTab: visible
            Accessible.role: Accessible.Button
            Accessible.name: root.showThought ? "Hide the thinking" : "Show the thinking"
            Keys.onReturnPressed: root.showThought = !root.showThought
            Keys.onSpacePressed: root.showThought = !root.showThought
            Row {
                id: thoughtRow
                spacing: Tokens.space1
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.showThought ? "expand_less" : "expand_more"
                    size: Tokens.iconSm
                    color: Colors.on.surfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    style: "labelLg"
                    color: Colors.on.surfaceVariant
                    text: root.streaming && (root.msg.text ?? "") === "" ? "Thinking…" : "Thought it through"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showThought = !root.showThought
            }
        }
        Rectangle {
            width: parent.width
            height: thought.implicitHeight + Tokens.space3 * 2
            visible: !root.mine && root.showThought && (root.msg.reasoning ?? "") !== ""
            radius: Tokens.radiusLg
            color: Colors.surfaceContainer
            TextEdit {
                id: thought
                x: Tokens.space4
                y: Tokens.space3
                width: parent.width - Tokens.space4 * 2
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                font: Type.font("bodyMd")
                color: Colors.on.surfaceVariant
                text: root.msg.reasoning ?? ""
            }
        }

        // Before the first word: three dots that rise in turn.
        Row {
            visible: root.streaming && (root.msg.text ?? "") === "" && (root.msg.reasoning ?? "") === ""
            spacing: Tokens.space1
            Accessible.role: Accessible.StaticText
            Accessible.name: "Coral is thinking"
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: Tokens.space2
                    height: width
                    radius: width / 2
                    color: Colors.on.surfaceVariant
                    transform: Translate {
                        y: dot.value
                    }
                    Spring {
                        id: dot
                        spec: Motion.spatialBouncy
                        target: 0
                    }
                    Timer {
                        interval: Tokens.coralBeat / Motion.speed
                        repeat: true
                        running: parent.visible && !Motion.reduceMotion
                        triggeredOnStart: true
                        onTriggered: lift.restart()
                    }
                    Timer {
                        id: lift
                        interval: Math.max(1, Motion.stagger(index * 4))
                        onTriggered: dot.kick(-Tokens.space1)
                    }
                }
            }
        }

        TextEdit {
            width: parent.width
            visible: !root.mine && text !== ""
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            textFormat: root.msg.error ? TextEdit.PlainText : TextEdit.MarkdownText
            font: Type.font("bodyLg")
            color: root.msg.error ? Colors.error : Colors.on.surface
            selectionColor: Colors.primaryContainer
            selectedTextColor: Colors.on.primaryContainer
            text: root.mine ? "" : root.msg.text ?? ""
            onLinkActivated: link => Qt.openUrlExternally(link)
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        Flow {
            width: parent.width
            visible: !root.mine && (root.msg.actions ?? []).length > 0
            spacing: Tokens.space2
            Repeater {
                model: root.mine ? [] : root.msg.actions ?? []
                PillButton {
                    required property var modelData
                    required property int index
                    accent: index === 0
                    text: modelData.label
                    onClicked: Coral.runAction(modelData)
                }
            }
        }

        // ── tools, on hover (always for the last reply) ──
        Row {
            anchors.right: root.mine ? parent.right : undefined
            spacing: Tokens.spaceHalf
            opacity: (hover.hovered || (root.last && !root.mine)) && !root.streaming && !root.editing ? 1 : 0
            enabled: opacity > 0

            CoralToolButton {
                icon: "content_copy"
                label: "Copy"
                onClicked: Quickshell.clipboardText = root.msg.text ?? ""
            }
            CoralToolButton {
                visible: root.mine
                icon: "edit"
                label: "Edit and ask again"
                onClicked: {
                    editor.text = root.msg.text ?? "";
                    root.editing = true;
                    editor.forceActiveFocus();
                    editor.cursorPosition = editor.length;
                }
            }
            CoralToolButton {
                visible: !root.mine && root.last
                icon: "refresh"
                label: "Ask again"
                onClicked: Coral.regenerate()
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.mine && (root.msg.model ?? "") !== ""
                leftPadding: Tokens.space2
                style: "monoSm"
                color: Colors.on.surfaceVariant
                text: root.msg.model ?? ""
            }
        }
    }

    function save() {
        if (editor.text.trim() === "")
            return;
        editing = false;
        Coral.edit(index, editor.text);
    }

    // An attachment: an image as a thumbnail, a file as a chip with its name.
    component AttachmentChip: Item {
        id: chip
        property var file: ({})
        width: file.kind === "image" ? Tokens.coralAppThumb : fileRow.implicitWidth + Tokens.space3 * 2
        height: file.kind === "image" ? Tokens.coralAppThumb : Tokens.chipHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: (file.kind === "image" ? "Image " : "File ") + (file.name ?? "")

        ShapeImage {
            anchors.fill: parent
            visible: chip.file.kind === "image"
            shape: "squircle"
            source: visible ? "file://" + chip.file.path : ""
            color: Colors.surfaceContainerHigh
            icon: "image"
            iconColor: Colors.on.surfaceVariant
        }
        Rectangle {
            anchors.fill: parent
            visible: chip.file.kind !== "image"
            radius: height / 2
            color: Colors.surfaceContainerHigh
            Row {
                id: fileRow
                anchors.centerIn: parent
                spacing: Tokens.space1
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "description"
                    size: Tokens.iconSm
                    color: Colors.on.surfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Tokens.coralMenuWidth)
                    elide: Text.ElideMiddle
                    style: "chipLabel"
                    color: Colors.on.surface
                    text: chip.file.name ?? ""
                }
            }
        }
    }
}
