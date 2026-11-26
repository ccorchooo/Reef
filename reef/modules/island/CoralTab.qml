import QtQuick
import qs.theme
import qs.services
import qs.components

// The Island's Coral tab (parts/Island-Coral; Super+C, search's "Ask Coral"): the
// conversation and an Ask field.
//
// Header: Coral's mark (it hops round while Coral thinks or replies), the name, the model
// and where it runs (mono), and New conversation and Close. Questions sit right in
// island-container-high bubbles; replies on the black, in Markdown, with the action
// buttons Coral offers (the first in island-accent). The conversation scrolls past
// coral-chat-max-height and follows a streaming reply. Enter asks; while Coral answers,
// the send button stops it.
Column {
    id: root

    spacing: Tokens.space3_5

    // On screen (expanded on this tab): replies aren't "unread" then.
    readonly property bool shown: visible && IslandState.expanded
    onShownChanged: Coral.watching(shown)

    function focusFirst() {
        field.forceActiveFocus();
    }

    function send() {
        if (Coral.busy) {
            Coral.stop();
            return;
        }
        if (input.text.trim() === "")
            return;
        Coral.ask(input.text);
        input.text = "";
    }

    // ── header ──
    Row {
        width: parent.width
        spacing: Tokens.space2_5

        // Coral's mark: an accent cookie on a dark disc, hopping round while busy.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralAvatar
            height: Tokens.coralAvatar
            Accessible.ignored: true

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colors.islandContainerHigh
            }
            ShapeItem {
                anchors.centerIn: parent
                width: Tokens.iconSm
                height: width
                radii: Shapes.sample("cookie6", width, height)
                color: Colors.islandAccent
                rotation: spin.value
            }
            Spring {
                id: spin
                spec: Motion.spatialBouncy
                target: 0
            }
            Timer {
                interval: Tokens.coralBeat / Motion.speed
                repeat: true
                running: Coral.busy && root.shown && !Motion.reduceMotion
                onTriggered: spin.target += Tokens.coralBeatAngle
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.coralAvatar - Tokens.coralButton * (CoralVoice.available ? 4 : 3) - parent.spacing * (CoralVoice.available ? 5 : 4)
            StyledText {
                style: "titleMdEmphasized"
                color: Colors.on.island
                text: "Coral"
                rond: 100
            }
            StyledText {
                width: parent.width
                elide: Text.ElideRight
                style: "monoSm"
                color: Colors.on.islandVariant
                text: (Coral.model || "No model yet") + (Coral.place ? " · " + Coral.place : "")
            }
        }

        IslandButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: CoralVoice.available
            width: Tokens.coralButton
            height: Tokens.coralButton
            iconSize: Tokens.iconSm
            filled: false
            icon: "graphic_eq"
            label: "Switch to voice"
            onClicked: CoralVoice.start()
        }
        IslandButton {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralButton
            height: Tokens.coralButton
            iconSize: Tokens.iconSm
            filled: false
            icon: "open_in_new"
            label: "Open in the Coral app"
            onClicked: {
                IslandState.close();
                Coral.openApp();
            }
        }
        IslandButton {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralButton
            height: Tokens.coralButton
            iconSize: Tokens.iconSm
            filled: false
            icon: "edit_square"
            label: "New conversation"
            enabledState: Coral.messages.length > 0
            onClicked: {
                Coral.clear();
                field.forceActiveFocus();
            }
        }
        IslandButton {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralButton
            height: Tokens.coralButton
            iconSize: Tokens.iconSm
            filled: false
            icon: "close"
            label: "Close"
            onClicked: IslandState.close()
        }
    }

    // ── the conversation ──
    Flickable {
        id: scroll
        width: parent.width
        visible: Coral.messages.length > 0
        height: Math.min(contentHeight, Tokens.coralChatMaxHeight)
        contentWidth: width
        contentHeight: chat.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Follow the newest text.
        onContentHeightChanged: contentY = Math.max(0, contentHeight - height)

        Column {
            id: chat
            width: scroll.width
            spacing: Tokens.space3_5

            Repeater {
                model: Coral.messages

                Item {
                    id: message
                    required property var modelData
                    required property int index
                    readonly property bool mine: modelData.role === "user"
                    readonly property bool last: index === Coral.messages.length - 1
                    width: chat.width
                    height: mine ? bubble.height : reply.implicitHeight

                    // A question: right, in a bubble with a small corner by the edge.
                    Rectangle {
                        id: bubble
                        visible: message.mine
                        anchors.right: parent.right
                        width: Math.min(Tokens.coralBubbleWidth, question.implicitWidth + Tokens.space3_5 * 2)
                        height: question.implicitHeight + Tokens.space2_5 * 2
                        color: Colors.islandContainerHigh
                        topLeftRadius: Tokens.coralBubbleRadius
                        topRightRadius: Tokens.coralBubbleRadius
                        bottomLeftRadius: Tokens.coralBubbleRadius
                        bottomRightRadius: Tokens.coralBubbleTail

                        StyledText {
                            id: question
                            x: Tokens.space3_5
                            y: Tokens.space2_5
                            width: Math.min(implicitWidth, Tokens.coralBubbleWidth - Tokens.space3_5 * 2)
                            wrapMode: Text.Wrap
                            style: "bodyMd"
                            color: Colors.on.island
                            text: message.mine ? message.modelData.text : ""
                        }
                    }

                    // A reply: left, Markdown, then its actions.
                    Column {
                        id: reply
                        visible: !message.mine
                        width: Math.min(parent.width, Tokens.coralReplyWidth)
                        spacing: Tokens.space2_5

                        // Before the first word: three dots that rise in turn.
                        Row {
                            visible: message.last && Coral.status === "thinking"
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
                                    color: Colors.on.islandVariant
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

                        StyledText {
                            width: parent.width
                            visible: text !== ""
                            wrapMode: Text.Wrap
                            textFormat: message.modelData.error ? Text.PlainText : Text.MarkdownText
                            style: "bodyMd"
                            color: message.modelData.error ? Colors.error : Colors.on.island
                            linkColor: Colors.islandAccent
                            text: message.mine ? "" : message.modelData.text
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }

                        Flow {
                            width: parent.width
                            visible: (message.modelData.actions ?? []).length > 0
                            spacing: Tokens.space2
                            Repeater {
                                model: message.mine ? [] : message.modelData.actions ?? []
                                IslandTextButton {
                                    required property var modelData
                                    required property int index
                                    height: Tokens.coralButton
                                    textStyle: index === 0 ? "toastAction" : "toastLabel"
                                    text: modelData.label
                                    color: index === 0 ? Colors.islandAccent : Colors.islandContainerHigh
                                    contentColor: index === 0 ? Colors.on.islandAccent : Colors.on.island
                                    onClicked: Coral.runAction(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── ask ──
    FocusScope {
        id: field
        width: parent.width
        height: Tokens.coralFieldHeight

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Colors.islandContainer
            border.width: input.activeFocus ? 2 : 0
            border.color: Colors.islandAccent
        }

        TextInput {
            id: input
            anchors.left: parent.left
            anchors.right: micButton.visible ? micButton.left : sendButton.left
            anchors.leftMargin: Tokens.space4
            anchors.rightMargin: Tokens.space2
            anchors.verticalCenter: parent.verticalCenter
            focus: true
            clip: true
            color: Colors.on.island
            selectionColor: Colors.islandAccent
            selectedTextColor: Colors.on.islandAccent
            font: Type.font("bodyMd")
            Accessible.role: Accessible.EditableText
            Accessible.name: "Ask Coral"
            Keys.onReturnPressed: root.send()
            Keys.onEnterPressed: root.send()

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                style: "bodyMd"
                color: Colors.on.islandVariant
                text: Coral.messages.length > 0 ? "Ask a follow-up…" : "Ask Coral…"
            }
        }

        IslandButton {
            id: micButton
            visible: CoralVoice.available
            anchors.right: sendButton.left
            anchors.rightMargin: Tokens.space1
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralButton
            height: Tokens.coralButton
            iconSize: Tokens.iconSm
            filled: false
            color: Qt.alpha(Colors.islandContainer, 0)
            contentColor: Colors.on.islandVariant
            icon: "mic"
            label: "Speak"
            onClicked: CoralVoice.start()
        }

        // Send; while Coral answers, Stop.
        IslandButton {
            id: sendButton
            anchors.right: parent.right
            anchors.rightMargin: (parent.height - height) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.coralButton
            height: Tokens.coralButton
            radius: Tokens.radiusMd
            iconSize: Tokens.iconSm
            icon: Coral.busy ? "stop" : "arrow_upward"
            label: Coral.busy ? "Stop" : "Send"
            color: Colors.islandAccent
            contentColor: Colors.on.islandAccent
            enabledState: Coral.busy || input.text.trim() !== ""
            onClicked: root.send()
        }
    }
}
