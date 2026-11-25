import QtQuick
import qs.theme
import qs.services
import qs.components

// The Island's Clipboard tab (parts/Island-Clipboard; Super+V): a search field and the
// history, pinned entries first on island-container-high. Each row has a glyph (a swatch
// for colors), the entry (mono for commands, paths and colors) and its age.
// Click or Enter copies it back and closes the Island; hovering shows pin and remove.
// Up/Down move through the rows from the field; Delete removes the selected one.
Column {
    id: root

    spacing: Tokens.space3

    property int current: 0
    property real now: Date.now()

    function focusFirst() {
        Clipboard.refresh();
        field.clear();
        current = 0;
        field.forceActiveFocus();
    }

    function choose(entry) {
        if (!entry)
            return;
        Clipboard.copy(entry);
        IslandState.close();
    }

    Timer {
        running: root.visible
        repeat: true
        interval: 30000
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    IslandSearchField {
        id: field
        width: parent.width
        placeholder: "Search clipboard"
        onTextChanged: {
            Clipboard.query = text;
            root.current = 0;
        }
        onMoved: by => {
            root.current = Math.max(0, Math.min(list.count - 1, root.current + by));
            list.positionViewAtIndex(root.current, ListView.Contain);
        }
        onAccepted: root.choose(Clipboard.results[root.current])
        Keys.onDeletePressed: event => {
            // With the field empty, Delete removes the selected entry.
            if (text !== "" || list.count === 0) {
                event.accepted = false;
                return;
            }
            Clipboard.remove(Clipboard.results[root.current]);
        }
    }

    ListView {
        id: list
        width: parent.width
        height: Math.max(Tokens.islandRowHeight, Math.min(contentHeight, Tokens.islandListMaxHeight))
        clip: true
        spacing: Tokens.space1
        boundsBehavior: Flickable.StopAtBounds
        model: Clipboard.results
        currentIndex: root.current
        keyNavigationEnabled: false

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            style: "islandRowLabel"
            color: Colors.on.islandVariant
            text: Clipboard.query !== "" ? "No matches" : "Clipboard is empty"
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property var entry: modelData
            readonly property bool selected: index === root.current
            readonly property bool mono: ["code", "color", "path"].includes(entry.kind)
            readonly property bool showActions: mouse.containsMouse || pinButton.activeFocus || removeButton.activeFocus

            width: list.width
            height: Tokens.islandRowHeight

            activeFocusOnTab: true
            Accessible.role: Accessible.ListItem
            Accessible.name: (entry.pinned ? "Pinned: " : "") + entry.label
            Keys.onReturnPressed: root.choose(entry)
            Keys.onSpacePressed: root.choose(entry)
            Keys.onDeletePressed: Clipboard.remove(entry)

            Rectangle {
                anchors.fill: parent
                radius: Tokens.radiusMd
                color: bg.value
                border.width: row.activeFocus ? 2 : 0
                border.color: Colors.islandAccent
                ColorSpring {
                    id: bg
                    spec: Motion.effectsFast
                    target: row.entry.pinned ? Colors.islandContainerHigh
                        : row.selected || mouse.containsMouse ? Colors.islandContainer : Qt.alpha(Colors.islandContainer, 0)
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = row.index
                onClicked: root.choose(row.entry)
            }

            // Glyph
            Item {
                id: glyph
                x: Tokens.space3
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.iconSm
                height: Tokens.iconSm

                Rectangle {
                    anchors.centerIn: parent
                    visible: row.entry.kind === "color" && !row.entry.pinned
                    width: Tokens.clipboardSwatch
                    height: Tokens.clipboardSwatch
                    radius: Tokens.radiusFillCap
                    color: row.entry.kind === "color" ? row.entry.text.trim() : "transparent"
                }
                Icon {
                    anchors.centerIn: parent
                    visible: row.entry.pinned || row.entry.kind !== "color"
                    size: Tokens.iconSm
                    filled: row.entry.pinned
                    color: row.entry.pinned ? Colors.islandAccent : Colors.on.islandVariant
                    name: row.entry.pinned ? "push_pin"
                        : ({ image: "image", path: "folder", code: "terminal", text: "notes" })[row.entry.kind] ?? "notes"
                }
            }

            StyledText {
                anchors.left: glyph.right
                anchors.leftMargin: Tokens.space3
                anchors.right: trailing.left
                anchors.rightMargin: Tokens.space3
                anchors.verticalCenter: parent.verticalCenter
                style: row.mono ? "monoMd" : "islandRowLabel"
                color: Colors.on.island
                elide: Text.ElideRight
                maximumLineCount: 1
                text: row.entry.label
            }

            Item {
                id: trailing
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space3
                anchors.verticalCenter: parent.verticalCenter
                width: row.showActions ? actions.implicitWidth : age.implicitWidth
                height: parent.height

                StyledText {
                    id: age
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !row.showActions
                    style: "bodySm"
                    color: Colors.on.islandVariant
                    text: row.entry.pinned ? "Pinned" : Clipboard.age(row.entry.seen, root.now)
                }

                Row {
                    id: actions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space1
                    opacity: row.showActions ? 1 : 0
                    enabled: row.showActions || row.activeFocus

                    IslandButton {
                        id: pinButton
                        visible: row.entry.kind !== "image"
                        width: Tokens.islandButtonSm
                        height: Tokens.islandButtonSm
                        iconSize: Tokens.iconSm
                        icon: "push_pin"
                        filled: row.entry.pinned
                        label: row.entry.pinned ? "Unpin" : "Pin"
                        color: Qt.alpha(Colors.islandContainerHigh, 0)
                        contentColor: row.entry.pinned ? Colors.islandAccent : Colors.on.islandVariant
                        onClicked: row.entry.pinned ? Clipboard.unpin(row.entry) : Clipboard.pin(row.entry)
                    }
                    IslandButton {
                        id: removeButton
                        width: Tokens.islandButtonSm
                        height: Tokens.islandButtonSm
                        iconSize: Tokens.iconSm
                        icon: "close"
                        filled: false
                        label: "Remove"
                        color: Qt.alpha(Colors.islandContainerHigh, 0)
                        contentColor: Colors.on.islandVariant
                        onClicked: Clipboard.remove(row.entry)
                    }
                }
            }
        }
    }
}
