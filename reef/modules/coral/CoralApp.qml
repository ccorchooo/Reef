import QtQuick
import QtQuick.Dialogs
import Quickshell
import qs.theme
import qs.services
import qs.components

// The Coral app (SURFACES.md → Coral → App): every conversation, with the model, files and
// tools a chat needs. A normal window like Settings: a sidebar on surface-container (New
// conversation, search, the conversations by Today / Yesterday / Previous 7 days / Older,
// the current one on secondary-container; double-click renames, the bin asks once more),
// and the conversation on surface-container-low, its column at most coral-app-column wide:
// a header (title, the model menu, where it runs), the messages (CoralMessage) or, empty,
// Coral's mark and a few starting points, and the composer (CoralComposer).
// Files can be dropped anywhere on the window. Ctrl+N starts a new conversation; Escape
// stops a reply. It shares its conversations with the Island's Coral tab and voice mode.
FloatingWindow {
    id: root

    title: "Coral"
    readonly property real screenWidth: screen?.width ?? Quickshell.screens[0]?.width ?? Tokens.coralAppWidth
    readonly property real screenHeight: screen?.height ?? Quickshell.screens[0]?.height ?? Tokens.coralAppHeight
    implicitWidth: Math.round(Math.min(Tokens.coralAppWidth, screenWidth - Tokens.space6 * 2))
    implicitHeight: Math.round(Math.min(Tokens.coralAppHeight, screenHeight - Tokens.cayHeight - Tokens.space6 * 2))
    minimumSize: Qt.size(Math.min(implicitWidth, Tokens.settingsNavWidth + Tokens.coralAppColumn / 2), Math.min(implicitHeight, Tokens.coralAppHeight / 2))
    color: Colors.surfaceContainerLow

    onClosed: Coral.appOpen = false
    Component.onCompleted: {
        Coral.watching(true);
        if (Coral.models.length === 0)
            Coral.refreshModels();
        Qt.callLater(() => composer.focusField());
    }
    Component.onDestruction: Coral.watching(false)

    property string query: ""
    property bool menuOpen: false

    // Conversations by when they were last used, filtered by the search.
    readonly property var rows: {
        const q = query.trim().toLowerCase();
        const day = 86400000;
        const today = new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate()).getTime();
        const groups = [["Today", today], ["Yesterday", today - day], ["Previous 7 days", today - 7 * day], ["Older", -Infinity]];
        const out = [];
        let group = "";
        for (const c of Coral.chats) {
            if (q !== "" && !c.title.toLowerCase().includes(q) && !(c.messages ?? []).some(m => (m.text ?? "").toLowerCase().includes(q)))
                continue;
            const g = groups.find(g => (c.updated ?? 0) >= g[1])[0];
            if (g !== group) {
                out.push({ header: g });
                group = g;
            }
            out.push({ chat: c });
        }
        return out;
    }

    FileDialog {
        id: picker
        title: "Attach to the conversation"
        fileMode: FileDialog.OpenFiles
        onAccepted: Coral.attach(selectedFiles.map(u => u.toString()))
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            Coral.newChat();
            composer.focusField();
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.menuOpen)
                root.menuOpen = false;
            else if (Coral.busy)
                Coral.stop();
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: event => {
            if (event.hasUrls)
                Coral.attach(event.urls.map(u => u.toString()));
        }
    }

    // ── sidebar ─────────────────────────────────────────────────
    Rectangle {
        id: nav
        width: Tokens.settingsNavWidth
        height: parent.height
        color: Colors.surfaceContainer
        Accessible.role: Accessible.List
        Accessible.name: "Conversations"

        Column {
            id: navTop
            x: Tokens.space3
            y: Tokens.space4
            width: nav.width - Tokens.space3 * 2
            spacing: Tokens.space2

            // New conversation
            Item {
                id: newRow
                width: parent.width
                height: Tokens.settingsNavRow
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "New conversation"
                Keys.onReturnPressed: newMouse.clicked(null)
                Keys.onSpacePressed: newMouse.clicked(null)
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colors.primaryContainer
                    border.width: newRow.activeFocus ? 2 : 0
                    border.color: Colors.primary
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.on.primaryContainer
                        opacity: newMouse.pressed ? Tokens.statePressedOpacity : newMouse.containsMouse ? Tokens.stateHoverOpacity : 0
                    }
                }
                Row {
                    x: Tokens.space3_5
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space3
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "edit_square"
                        size: Tokens.iconMd
                        color: Colors.on.primaryContainer
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        style: "tileLabel"
                        color: Colors.on.primaryContainer
                        text: "New conversation"
                    }
                }
                MouseArea {
                    id: newMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Coral.newChat();
                        composer.focusField();
                    }
                }
            }

            // Search conversations
            Rectangle {
                width: parent.width
                height: Tokens.settingsNavRow
                radius: height / 2
                color: Colors.surfaceContainerLow
                border.width: search.activeFocus ? 2 : 0
                border.color: Colors.primary
                Icon {
                    id: searchIcon
                    x: Tokens.space3_5
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: Tokens.iconSm
                }
                TextInput {
                    id: search
                    anchors.left: searchIcon.right
                    anchors.leftMargin: Tokens.space2
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.space3_5
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    color: Colors.on.surface
                    selectionColor: Colors.primaryContainer
                    selectedTextColor: Colors.on.primaryContainer
                    font: Type.font("segmentLabel")
                    activeFocusOnTab: true
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Search conversations"
                    onTextChanged: root.query = text
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        style: "segmentLabel"
                        color: Colors.on.surfaceVariant
                        text: "Search conversations"
                    }
                }
            }
        }

        Flickable {
            anchors.top: navTop.bottom
            anchors.topMargin: Tokens.space3
            anchors.bottom: parent.bottom
            width: parent.width
            contentHeight: list.implicitHeight + Tokens.space4
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                x: Tokens.space3
                width: nav.width - Tokens.space3 * 2
                spacing: Tokens.spaceHalf

                StyledText {
                    visible: root.rows.length === 0
                    x: Tokens.space3_5
                    style: "bodyMd"
                    color: Colors.on.surfaceVariant
                    text: root.query !== "" ? "No conversations match" : "No conversations yet"
                }

                Repeater {
                    model: root.rows
                    Loader {
                        required property var modelData
                        width: list.width
                        sourceComponent: modelData.header ? headerRow : chatRow
                        property var row: modelData
                    }
                }
            }
        }
    }

    Component {
        id: headerRow
        StyledText {
            topPadding: Tokens.space3
            bottomPadding: Tokens.space1
            leftPadding: Tokens.space3_5
            style: "searchSection"
            color: Colors.on.surfaceVariant
            text: parent.row.header
            Accessible.role: Accessible.Heading
        }
    }

    Component {
        id: chatRow
        Item {
            id: rowItem
            readonly property var chat: parent.row.chat
            readonly property bool current: chat.id === Coral.chatId
            property bool renaming: false
            property bool confirming: false
            height: Tokens.settingsNavRow
            activeFocusOnTab: true
            Accessible.role: Accessible.ListItem
            Accessible.name: chat.title
            Accessible.selected: current
            Keys.onReturnPressed: Coral.openChat(chat.id)
            Keys.onSpacePressed: Coral.openChat(chat.id)
            Keys.onDeletePressed: confirming ? Coral.deleteChat(chat.id) : (confirming = true)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_F2) {
                    rowItem.startRename();
                    event.accepted = true;
                }
            }

            function startRename() {
                nameField.text = chat.title;
                renaming = true;
                nameField.forceActiveFocus();
                nameField.selectAll();
            }

            Timer {
                running: rowItem.confirming
                interval: 3000
                onTriggered: rowItem.confirming = false
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: rowItem.current ? Colors.secondaryContainer : Qt.alpha(Colors.secondaryContainer, 0)
                border.width: rowItem.activeFocus ? 2 : 0
                border.color: Colors.primary
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.on.surface
                    opacity: rowMouse.pressed ? Tokens.statePressedOpacity : rowMouse.containsMouse && !rowItem.current ? Tokens.stateHoverOpacity : 0
                }
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Coral.openChat(rowItem.chat.id)
                onDoubleClicked: rowItem.startRename()
            }
            StyledText {
                visible: !rowItem.renaming
                x: Tokens.space3_5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.space3_5 - (rowMouse.containsMouse || rowItem.confirming ? Tokens.coralAppTool + Tokens.space2 : Tokens.space3_5)
                elide: Text.ElideRight
                style: rowItem.current ? "tileLabel" : "segmentLabel"
                color: rowItem.current ? Colors.on.secondaryContainer : Colors.on.surface
                text: rowItem.chat.title
            }
            TextInput {
                id: nameField
                visible: rowItem.renaming
                x: Tokens.space3_5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.space3_5 * 2
                clip: true
                font: Type.font("segmentLabel")
                color: Colors.on.surface
                selectionColor: Colors.primaryContainer
                selectedTextColor: Colors.on.primaryContainer
                Accessible.role: Accessible.EditableText
                Accessible.name: "Rename the conversation"
                onAccepted: {
                    Coral.renameChat(rowItem.chat.id, text);
                    rowItem.renaming = false;
                }
                onActiveFocusChanged: if (!activeFocus) rowItem.renaming = false
                Keys.onEscapePressed: rowItem.renaming = false
            }
            CoralToolButton {
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space1
                anchors.verticalCenter: parent.verticalCenter
                visible: (rowMouse.containsMouse || rowItem.confirming) && !rowItem.renaming
                icon: rowItem.confirming ? "delete_forever" : "delete"
                label: rowItem.confirming ? "Delete for good" : "Delete the conversation"
                color: rowItem.confirming ? Colors.error : Colors.on.surfaceVariant
                onClicked: rowItem.confirming ? Coral.deleteChat(rowItem.chat.id) : (rowItem.confirming = true)
            }
        }
    }

    // ── the conversation ────────────────────────────────────────
    Item {
        id: main
        anchors.left: nav.right
        anchors.right: parent.right
        height: parent.height

        // Header: title, model, where it runs.
        Item {
            id: header
            width: parent.width
            height: Tokens.settingsNavRow + Tokens.space4 * 2

            StyledText {
                x: Tokens.space6
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.space6 * 2 - modelButton.width - Tokens.space3
                elide: Text.ElideRight
                style: "cardTitle"
                color: Colors.on.surface
                text: Coral.chat?.title ?? "New conversation"
                Accessible.role: Accessible.Heading
            }

            Item {
                id: modelButton
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space6
                anchors.verticalCenter: parent.verticalCenter
                width: modelRow.implicitWidth + Tokens.space4 * 2
                height: Tokens.settingsNavRow
                activeFocusOnTab: true
                Accessible.role: Accessible.ButtonMenu
                Accessible.name: "Model: " + (Coral.model || "default")
                Keys.onReturnPressed: root.toggleMenu()
                Keys.onSpacePressed: root.toggleMenu()
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: root.menuOpen ? Colors.secondaryContainer : Colors.surfaceContainerHigh
                    border.width: modelButton.activeFocus ? 2 : 0
                    border.color: Colors.primary
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.on.surface
                        opacity: modelMouse.pressed ? Tokens.statePressedOpacity : modelMouse.containsMouse ? Tokens.stateHoverOpacity : 0
                    }
                }
                Row {
                    id: modelRow
                    anchors.centerIn: parent
                    spacing: Tokens.space2
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, Tokens.coralMenuWidth - Tokens.space8)
                        elide: Text.ElideMiddle
                        style: "monoSm"
                        color: Colors.on.surface
                        text: (Coral.model || "Default model") + " · " + Coral.place
                    }
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.menuOpen ? "expand_less" : "expand_more"
                        size: Tokens.iconSm
                        color: Colors.on.surfaceVariant
                    }
                }
                MouseArea {
                    id: modelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMenu()
                }
            }
        }

        // Messages
        ListView {
            id: messages
            anchors.top: header.bottom
            anchors.bottom: composer.top
            anchors.bottomMargin: Tokens.space3
            width: parent.width
            visible: Coral.messages.length > 0
            clip: true
            spacing: Tokens.space5
            boundsBehavior: Flickable.StopAtBounds
            model: Coral.messages.length
            // Follow a reply as it streams, unless scrolled up to read.
            property bool atEnd: true
            onMovementEnded: atEnd = contentY + height >= contentHeight - Tokens.space8
            onContentHeightChanged: if (atEnd) positionViewAtEnd()
            onCountChanged: {
                atEnd = true;
                Qt.callLater(positionViewAtEnd);
            }
            header: Item {
                width: 1
                height: Tokens.space2
            }
            footer: Item {
                width: 1
                height: Tokens.space4
            }
            delegate: Item {
                required property int index
                width: messages.width
                height: message.implicitHeight
                CoralMessage {
                    id: message
                    index: parent.index
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(messages.width - Tokens.space6 * 2, Tokens.coralAppColumn)
                }
            }
        }

        // Empty: Coral's mark and a few starting points.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -composer.height / 2
            visible: Coral.messages.length === 0
            spacing: Tokens.space5
            width: Math.min(parent.width - Tokens.space6 * 2, Tokens.coralAppColumn)

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Tokens.coralOrbCore
                height: width
                radius: width / 2
                color: Colors.primaryContainer
                ShapeItem {
                    anchors.centerIn: parent
                    width: Tokens.coralOrbMark
                    height: width
                    radii: Shapes.sample("cookie6", width, height)
                    color: Colors.primary
                }
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "headlineSm"
                rond: 100
                color: Colors.on.surface
                text: "What can I help with?"
                Accessible.role: Accessible.Heading
            }
            Flow {
                width: parent.width
                spacing: Tokens.space2
                layoutDirection: Qt.LeftToRight
                Repeater {
                    model: [
                        { label: "What can you do in Reef?", ask: "What can you do for me in Reef?" },
                        { label: "Plan my day", ask: "Help me plan my day. Ask me what I have on first." },
                        { label: "Write a shell script", ask: "Write a bash script that " },
                        { label: "Explain a file", attach: true }
                    ]
                    PillButton {
                        required property var modelData
                        text: modelData.label
                        onClicked: {
                            if (modelData.attach)
                                picker.open();
                            else if (modelData.ask.endsWith(" "))
                                composer.prefill(modelData.ask);
                            else
                                Coral.ask(modelData.ask);
                        }
                    }
                }
            }
        }

        CoralComposer {
            id: composer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tokens.space5
            width: Math.min(parent.width - Tokens.space6 * 2, Tokens.coralAppColumn)
            onAttachRequested: picker.open()
        }

        // Files over the window
        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.space4
            visible: drop.containsDrag
            radius: Tokens.radiusXl
            color: Qt.alpha(Colors.primaryContainer, Tokens.scrimLightOpacity)
            border.width: 2
            border.color: Colors.primary
            Column {
                anchors.centerIn: parent
                spacing: Tokens.space2
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "upload_file"
                    size: Tokens.iconLg
                    color: Colors.on.primaryContainer
                }
                StyledText {
                    style: "titleMd"
                    color: Colors.on.primaryContainer
                    text: "Drop to attach"
                }
            }
        }

        // The model menu
        MouseArea {
            anchors.fill: parent
            visible: root.menuOpen
            onClicked: root.menuOpen = false
        }
        Rectangle {
            id: menu
            visible: root.menuOpen
            anchors.right: parent.right
            anchors.rightMargin: Tokens.space6
            y: header.height - Tokens.space2
            width: Tokens.coralMenuWidth
            height: Math.min(menuColumn.implicitHeight + Tokens.space2 * 2, main.height - y - Tokens.space6)
            radius: Tokens.radiusLg
            color: Colors.surfaceContainerHigh
            Accessible.role: Accessible.PopupMenu
            Accessible.name: "Models"

            Flickable {
                anchors.fill: parent
                anchors.margins: Tokens.space2
                contentHeight: menuColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: menuColumn
                    width: parent.width
                    spacing: Tokens.spaceHalf
                    Repeater {
                        model: [""].concat(Coral.models)
                        ListRow {
                            required property var modelData
                            width: menuColumn.width
                            icon: (Coral.chatModel || "") === modelData ? "check" : ""
                            title: modelData === "" ? "Default" : modelData
                            subtitle: modelData === "" ? (Coral.target?.model || "The endpoint's first model") : ""
                            onClicked: {
                                Coral.setModel(modelData);
                                root.menuOpen = false;
                            }
                        }
                    }
                    StyledText {
                        visible: Coral.models.length === 0
                        leftPadding: Tokens.space3
                        style: "bodySm"
                        color: Colors.on.surfaceVariant
                        text: "Looking for models…"
                    }
                }
            }
        }
    }

    function toggleMenu() {
        menuOpen = !menuOpen;
        if (menuOpen)
            Coral.refreshModels();
    }
}
